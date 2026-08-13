require "rails_helper"
RSpec.describe "Elements", type: :request do
  let!(:element) { create(:element, atomic_number: 1_000, symbol: "T1000", name: "水素", english_name: "Hydrogen", common_state: "気体", period: 1, group_number: 18) }
  it "周期表と元素詳細を表示し、未ログイン時の投稿導線はユーザー登録モーダルを開く" do
    get elements_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("周期表", "イラスト集", "水素の情報を表示", 'href="/illustrations"')
    expect(response.body.index("PERIODIC TABLE")).to be < response.body.index("気になる元素記号を選んで、詳細を調べてみよう。")
    expect(response.body).to include('class="mt-1 flex justify-center"')
    expect(response.body).to include('data-action="modal#open periodic-table#close"', 'data-modal-dialog-param="registration"')

    get element_path(element)
    expect(response.body).to include("この元素を投稿する", 'data-action="modal#open"', 'data-modal-dialog-param="registration"')

    sign_in(create(:user))
    get elements_path
    expect(response.body).to include('data-action="periodic-table#post"', "data-element-post-url=\"/illustrations/new?element_id=#{element.id}\"")
    illustration = create(:illustration, element: element, monster_name: "水素の公開イラスト", published: true)
    get element_path(element)
    expect(response.body).to include("水素", "Hydrogen", "18族1周期", "常温での状態", "気体", "水素の公開イラスト", "ILLUSTRATIONS", "新着", "人気", "button-interaction", 'data-turbo="false"', "href=\"/illustrations/new?element_id=#{element.id}\"")
    expect(response.body).to include('sm:flex-nowrap', 'whitespace-nowrap', 'gap-x-3 gap-y-1')
    expect(response.body).to include(illustration.element.symbol)
    expect(response.body).not_to include("作品数", "水素のイラスト")
  end
  it "元素詳細の関連イラストを10件ずつ表示し、並び替え条件をページ移動後も維持する" do
    11.times do |index|
      illustration = create(:illustration, element: element, monster_name: "元素ページ作品#{index + 1}", created_at: (index + 1).minutes.ago)
      create_list(:like, index == 10 ? 2 : 1, illustration: illustration)
    end

    get element_path(element, sort: "popular", page: 2)

    expect(response.body).to include("2 / 2", "元素ページ作品1")
    expect(response.body).to include('href="/elements/' + element.id.to_s + '?page=1&amp;sort=popular"')
  end

  it "元素詳細内のイラストを新着順と人気順で切り替えられる" do
    user = create(:user)
    newest_illustration = create(:illustration, element: element, monster_name: "新着イラスト", created_at: 1.hour.ago)
    popular_illustration = create(:illustration, element: element, monster_name: "人気イラスト", created_at: 2.hours.ago)
    create_list(:like, 2, illustration: popular_illustration)

    get element_path(element)
    expect(response.body).to include('aria-current="page"', "新着イラスト", "人気イラスト")
    expect(response.body.index("新着イラスト")).to be < response.body.index("人気イラスト")

    get element_path(element, sort: "popular")
    expect(response.body).to include('href="/elements/' + element.id.to_s + '?sort=popular"', 'aria-current="page"')
    expect(response.body.index("人気イラスト")).to be < response.body.index("新着イラスト")
  end
end
