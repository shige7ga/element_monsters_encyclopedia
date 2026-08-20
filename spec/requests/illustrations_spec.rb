require "rails_helper"
require "tempfile"

RSpec.describe "Illustrations", type: :request do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:element) { create(:element) }
  let!(:published_illustration) { create(:illustration, user: owner, element: element, monster_name: "公開作品", published: true) }
  let!(:private_illustration) { create(:illustration, user: owner, element: element, monster_name: "非公開作品", published: false) }

  it "未ログイン時は公開作品だけを一覧表示し、投稿画面はログインを要求する" do
    get illustrations_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("公開作品", "イラスト集", "周期表", "ILLUSTRATION GALLERY", "元素モンスターを見て、あなたの推し元素を探そう")
    expect(response.body).to include("AIでモンスターを作る", 'href="/ai_generation_assist"')
    expect(response.body.index("イラスト集")).to be < response.body.index("周期表")
    expect(response.body).not_to include("非公開作品")

    get new_illustration_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "ログインユーザーは一覧からAI作成と通常投稿を選べる" do
    sign_in(owner)

    get illustrations_path

    document = Nokogiri::HTML(response.body)
    main_links = document.css("main a")

    expect(main_links.map(&:text)).to include("AIでモンスターを作る", "イラスト投稿")
    expect(main_links.find { |link| link.text == "AIでモンスターを作る" }["href"]).to eq(ai_generation_assist_path)
    expect(main_links.find { |link| link.text == "イラスト投稿" }["href"]).to eq(new_illustration_path)
  end

  it "一覧と人気一覧を12件ずつ表示し、ページ移動後も人気順を維持する" do
    13.times do |index|
      illustration = create(:illustration, element: element, monster_name: "ページネーション作品#{index + 1}", created_at: (index + 1).minutes.ago)
      create_list(:like, index == 10 ? 2 : 1, illustration: illustration)
    end

    get illustrations_path

    expect(response.body).to include("1 / 2", "次へ", "ページネーション作品1")
    expect(response.body).not_to include("ページネーション作品13")

    get illustrations_path(page: 2)

    expect(response.body).to include("2 / 2", "前へ", "ページネーション作品13")

    get popular_illustrations_path(page: 2)

    expect(response.body).to include("2 / 2", "人気", "ページネーション作品1")
    expect(response.body).to include('href="/illustrations/popular?page=1"')
  end

  it "投稿・編集フォームにモンスター名、説明、明示した送信ボタンを表示する" do
    sign_in(owner)

    get new_illustration_path
    expect(response.body).to include("モンスター名", "作成方法", "自作", "AI生成", "説明（モンスターの特徴・元素の覚え方など）", "あなたが創った元素モンスターを投稿して、みんなで図鑑を育てよう！", "かんたん元素モンスター作成アシスト", "投稿する", 'type="radio"', "ファイル選択", "画像を選択してください", 'class="sr-only"', 'data-controller="file-name"', 'change-&gt;file-name#update', 'data-file-name-target="name"')
    creation_type_inputs = response.body.scan(/<input[^>]*name="illustration\[creation_type\]"[^>]*>/)
    expect(creation_type_inputs).to have_attributes(length: 2)
    expect(creation_type_inputs).not_to include(a_string_matching(/checked/))

    get edit_illustration_path(published_illustration)
    expect(response.body).to include("更新する")
  end

  it "element_id付きの投稿画面では対象元素を初期選択する" do
    sign_in(owner)

    get new_illustration_path(element_id: element.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<option selected=\"selected\" value=\"#{element.id}\"")
  end

  it "アシスト経由の投稿画面では元素とAI生成を初期選択する" do
    sign_in(owner)

    get new_illustration_path(element_id: element.id, from_ai_assist: 1)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<option selected=\"selected\" value=\"#{element.id}\"")
    creation_type = Nokogiri::HTML(response.body).at_css("input[name='illustration[creation_type]'][value='ai_generated']")
    expect(creation_type["checked"]).to eq("checked")
  end

  it "通常の投稿画面では元素を初期選択しない" do
    sign_in(owner)

    get new_illustration_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("<option selected=\"selected\" value=\"#{element.id}\"")
  end

  it "詳細と一覧でモンスター名・説明を表示し、画像をobject-containで収める" do
    get illustration_path(published_illustration)

    expect(response.body).to include("公開作品", published_illustration.description, "h-full w-full object-contain object-center", "md:grid-cols-[minmax(0,1.1fr)_minmax(0,0.9fr)]", "mx-auto", "md:mx-0")
    expect(response.body).not_to include("items-center justify-center", "width: auto; height: auto; max-width: 100%; max-height: 100%; object-fit: contain; object-position: center;")
    expect(response.body).to include("min-w-0 flex-1", "mt-3", "justify-start")
    expect(response.body).not_to include("ILLUSTRATION", ">公開<")

    get illustrations_path
    expect(response.body).to include("aspect-square", "h-full w-full object-contain object-center", "flex-1 truncate")
    expect(response.body).not_to include("width: auto; height: auto; max-width: 100%; max-height: 100%; object-fit: contain; object-position: center;")
  end

  it "AI生成作品だけ詳細画面にAI生成バッジを表示する" do
    ai_illustration = create(:illustration, element: element, creation_type: "ai_generated")

    get illustration_path(ai_illustration)
    expect(response.body).to include("AI生成")

    get illustration_path(published_illustration)
    expect(response.body).not_to include(">AI生成<")
  end

  it "投稿者は自分の非公開作品を閲覧できるが、他人は閲覧できない" do
    sign_in(owner)
    get illustrations_path
    expect(response.body).to include("非公開作品")

    get illustration_path(private_illustration)
    expect(response).to have_http_status(:ok)

    sign_out(owner)
    get illustration_path(private_illustration)
    expect(response).to redirect_to(illustrations_path)
  end

  it "投稿者以外の編集用URLへのアクセスを拒否する" do
    sign_in(other_user)

    get edit_illustration_path(published_illustration)

    expect(response).to have_http_status(:not_found)
  end

  it "投稿者が作品を削除すると添付画像も削除する" do
    sign_in(owner)
    blob = published_illustration.image.blob

    delete illustration_path(published_illustration)

    expect(response).to redirect_to(illustrations_path)
    expect(Illustration).not_to exist(published_illustration.id)
    expect(ActiveStorage::Blob).not_to exist(blob.id)
  end

  it "投稿者以外の削除用URLへのアクセスを拒否する" do
    sign_in(other_user)

    delete illustration_path(published_illustration)

    expect(response).to have_http_status(:not_found)
    expect(Illustration).to exist(published_illustration.id)
  end

  it "ログインユーザーは画像付きのイラストを投稿できる" do
    sign_in(owner)

    Tempfile.create([ "illustration", ".png" ]) do |file|
      file.binmode
      file.write("image data")
      file.rewind
      upload = Rack::Test::UploadedFile.new(file.path, "image/png")

      post illustrations_path, params: {
        illustration: {
          element_id: element.id,
          image: upload,
          monster_name: "新しい投稿",
          description: "説明",
          creation_type: "ai_generated",
          published: "1"
        }
      }
    end

    illustration = Illustration.find_by!(monster_name: "新しい投稿")
    expect(response).to redirect_to(illustration_path(illustration))
    expect(illustration.user).to eq(owner)
    expect(illustration.description).to eq("説明")
    expect(illustration.creation_type).to eq("ai_generated")
    expect(illustration.image).to be_attached
  end

  it "投稿時のエラーを各入力項目の直下に表示し、入力内容を保持する" do
    sign_in(owner)

    post illustrations_path,
         params: {
           illustration: {
             element_id: "",
             monster_name: "あ" * 41,
             description: "あ" * 1001,
             creation_type: "",
             published: "invalid"
           }
         }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include(
      "対象元素 を選択してください",
      "イラスト画像 を添付してください",
      "モンスター名 は40文字以内で入力してください",
      "説明 は1000文字以内で入力してください",
      "作成方法 を選択してください",
      "公開設定 は公開または非公開の値を選択してください"
    )
    expect(response.body).to include('value="' + ("あ" * 41) + '"')
    expect(response.body).to include("textarea", "あ" * 1001)
    expect(response.body).not_to include("入力内容を確認してください。")
  end

  it "投稿者は画像を変更せずに有効な内容でイラストを編集できる" do
    sign_in(owner)

    patch illustration_path(published_illustration),
          params: {
            illustration: {
              element_id: element.id,
              monster_name: "  更新後モンスター  ",
              description: "  更新後の説明  ",
              creation_type: "self_made",
              published: "0"
            }
          }

    expect(response).to redirect_to(illustration_path(published_illustration))
    expect(published_illustration.reload).to have_attributes(
      monster_name: "更新後モンスター",
      description: "更新後の説明",
      creation_type: "self_made",
      published: false
    )
    expect(published_illustration.image).to be_attached
  end

  it "投稿者ページには公開作品だけを表示し、本人のページには非公開作品も表示する" do
    get user_path(owner)
    expect(response.body).to include("公開作品")
    expect(response.body).not_to include("非公開作品")

    sign_in(owner)
    get mypage_path
    expect(response.body).to include("公開作品", "非公開作品")
  end

  it "ログイン時の詳細画面では推し登録欄から推し元素図鑑へ移動できる" do
    sign_in(other_user)

    get illustration_path(published_illustration)

    expect(response.body).to include("推し元素図鑑へ", 'href="/encyclopedia_entries"', "flex-wrap items-center justify-between")
  end

  it "ログインユーザーはいいねと解除ができ、一覧と詳細に件数を表示する" do
    sign_in(other_user)

    post illustration_like_path(published_illustration)
    expect(response).to redirect_to(illustration_path(published_illustration))
    expect(published_illustration.likes.count).to eq(1)

    get illustrations_path
    expect(response.body).to include("♥", ">1<", "text-lg", "gap-1")
    expect(response.body).not_to include("♥ いいね済み")

    get illustration_path(published_illustration)
    expect(response.body).to include("♥", ">1<", "text-lg", "gap-1", "justify-start")
    expect(response.body).not_to include("♥ いいね済み")

    delete illustration_like_path(published_illustration)
    expect(response).to redirect_to(illustration_path(published_illustration))
    expect(published_illustration.likes.count).to eq(0)

    get illustration_path(published_illustration)
    expect(response.body).to include("♡", ">0<", "gap-1")
    expect(response.body).not_to include("♥0")
  end

  it "いいねと解除はTurbo Streamで対象ボタンだけを更新できる" do
    sign_in(other_user)
    turbo_headers = { "ACCEPT" => "text/vnd.turbo-stream.html" }

    post illustration_like_path(published_illustration), params: { alignment: "justify-start" }, headers: turbo_headers
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include('target="like_button_illustration_' + published_illustration.id.to_s + '"', "♥", ">1<", "justify-start")

    delete illustration_like_path(published_illustration), params: { alignment: "justify-start" }, headers: turbo_headers
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include('target="like_button_illustration_' + published_illustration.id.to_s + '"', "♡", ">0<", "justify-start")
  end

  it "同じユーザーが同じイラストへ繰り返しいいねしても1件だけ作成する" do
    sign_in(other_user)

    2.times { post illustration_like_path(published_illustration) }

    expect(other_user.likes.where(illustration: published_illustration).count).to eq(1)
  end

  it "未ログイン時のいいねはログインモーダルを開き、直接のいいねはログイン画面へ遷移する" do
    get illustration_path(published_illustration)
    expect(response.body).to include('data-action="modal#open"', 'data-modal-dialog-param="login"')
    expect(response.body).not_to include('href="/users/sign_in"')

    post illustration_like_path(published_illustration)
    expect(response).to redirect_to(new_user_session_path)
    expect(Like.count).to eq(0)
  end

  it "いいねしたイラスト一覧では自分がいいねした作品だけを表示する" do
    liked_illustration = create(:illustration, element: element, monster_name: "いいね済み作品")
    create(:like, user: other_user, illustration: liked_illustration)
    sign_in(other_user)

    get liked_illustrations_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("いいねしたイラスト", "いいね済み作品")
    expect(response.body).not_to include("公開作品")
  end

  it "人気一覧ではいいね数が多い公開作品を先に表示する" do
    popular_illustration = create(:illustration, element: element, monster_name: "人気作品")
    create_list(:like, 2, illustration: popular_illustration)
    create(:like, illustration: published_illustration)

    get popular_illustrations_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("イラスト集", "元素モンスターを見て、あなたの推し元素を探そう")
    expect(response.body).not_to include("人気イラスト", "たくさんのいいねを集めた元素モンスターを見てみよう", "いいねした作品")
    expect(response.body).to include('aria-current="page"', "border-cyan-300 text-cyan-200")
    expect(response.body.index("人気作品")).to be < response.body.index("公開作品")
  end

  it "他人の非公開作品にはいいねできない" do
    sign_in(other_user)

    post illustration_like_path(private_illustration)

    expect(response).to have_http_status(:not_found)
    expect(Like.count).to eq(0)
  end

  it "Xシェアリンクが表示される" do
    get illustration_path(published_illustration)

    expect(response.body).to include("𝕏 シェア")
    expect(response.body).to include("twitter.com/intent/tweet")
  end

  it "XシェアリンクへのOGP画像が認識できている" do
    get illustration_path(published_illustration)
    document = Nokogiri::HTML(response.body)
    og_image = document.at_css('meta[property="og:image"]')

    expect(og_image).to be_present
    expect(og_image["content"]).to start_with("http")
  end

  it "Xシェアリンクに作品名が含まれる" do
    get illustration_path(published_illustration)

    expect(response.body).to include(
      CGI.escape(
        "公開作品 | #{published_illustration.element.name}（#{published_illustration.element.symbol}・元素番号#{published_illustration.element.atomic_number}）by #{published_illustration.user.name} | 元素モンスターズ図鑑"
      )
    )
  end
end
