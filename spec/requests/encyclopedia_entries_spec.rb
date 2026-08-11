require "rails_helper"

RSpec.describe "Encyclopedia entries", type: :request do
  let(:user) { create(:user) }
  let(:element) { create(:element, atomic_number: 1, symbol: "H", name: "水素") }
  let(:next_element) { create(:element, atomic_number: 2, symbol: "He", name: "ヘリウム") }
  let(:illustration) { create(:illustration, element: element, published: true, monster_name: "水素モンスター") }

  it "未ログイン時は推し元素図鑑を閲覧できない" do
    get encyclopedia_entries_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "公開イラストを推し登録し、同元素の別イラストで更新できる" do
    replacement_illustration = create(:illustration, element: element, published: true, monster_name: "水素モンスター2")
    sign_in(user)

    post illustration_encyclopedia_entry_path(illustration)
    entry = user.encyclopedia_entries.find_by!(element: element)
    expect(entry.illustration).to eq(illustration)

    get illustration_path(replacement_illustration)
    expect(response.body).to include("推し登録", 'data-tip="推し元素図鑑に登録できます"', 'data-turbo-confirm="すでに推し元素登録がありますが、更新しますか？"')
    expect(response.body).not_to include("推し登録済み", "📖")

    expect { post illustration_encyclopedia_entry_path(replacement_illustration) }.not_to change(EncyclopediaEntry, :count)
    expect(entry.reload.illustration).to eq(replacement_illustration)
  end

  it "非公開イラストは推し登録できない" do
    private_illustration = create(:illustration, element: element, published: false)
    sign_in(user)

    get illustration_path(private_illustration)
    expect(response.body).not_to include("推し登録")

    post illustration_encyclopedia_entry_path(private_illustration)
    expect(response).to have_http_status(:not_found)
    expect(EncyclopediaEntry.count).to eq(0)
  end

  it "元素番号順に推し元素図鑑を表示し、登録状態に応じた詳細ページへ移動できる" do
    create(:encyclopedia_entry, user: user, element: element, illustration: illustration)
    next_element
    sign_in(user)

    get encyclopedia_entries_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("推し元素図鑑", "あなたの一推しの元素を登録しよう", "No. 1", "No. 2", "水素モンスター", "未登録")
    expect(response.body).to include('href="/illustrations/' + illustration.id.to_s + '"')
    expect(response.body).to include('href="/elements/' + next_element.id.to_s + '"')
    expect(response.body.index("No. 1")).to be < response.body.index("No. 2")
  end

  it "登録済みの推しイラストは解除できる" do
    create(:encyclopedia_entry, user: user, element: element, illustration: illustration)
    sign_in(user)

    get illustration_path(illustration)
    expect(response.body).to include("推し登録済み", "bg-emerald-300/15")

    expect { delete illustration_encyclopedia_entry_path(illustration) }.to change(EncyclopediaEntry, :count).by(-1)
    expect(response).to redirect_to(illustration_path(illustration))
  end

  it "推し登録と解除はTurbo Streamで対象ボタンだけを更新できる" do
    sign_in(user)
    turbo_headers = { "ACCEPT" => "text/vnd.turbo-stream.html" }

    post illustration_encyclopedia_entry_path(illustration), headers: turbo_headers
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include('target="encyclopedia_entry_button_illustration_' + illustration.id.to_s + '"', "推し登録済み")

    delete illustration_encyclopedia_entry_path(illustration), headers: turbo_headers
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include('target="encyclopedia_entry_button_illustration_' + illustration.id.to_s + '"', "推し登録")
    expect(response.body).not_to include("推し登録済み")
  end

  it "イラスト一覧カードには推し登録ボタンを表示しない" do
    illustration
    sign_in(user)

    get illustrations_path

    expect(response.body).not_to include("推し登録")
  end

  it "マイページのプロフィール枠から推し元素図鑑へ移動できる" do
    sign_in(user)

    get mypage_path

    expect(response.body).to include("推し元素図鑑", 'href="/encyclopedia_entries"')
  end
end
