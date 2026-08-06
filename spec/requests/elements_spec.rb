require "rails_helper"
RSpec.describe "Elements", type: :request do
  let!(:element) { create(:element, atomic_number: 1_000, symbol: "T1000", name: "水素", english_name: "Hydrogen", common_state: "気体") }
  it "周期表と元素詳細を表示し、投稿はログイン時だけ表示する" do
    get elements_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("周期表", "イラスト集", "水素の情報を表示", 'href="/illustrations"')
    expect(response.body.index("PERIODIC TABLE")).to be < response.body.index("気になる元素記号を選んで、詳細を調べてみよう。")
    expect(response.body).to include('class="mt-1 flex justify-center"')
    expect(response.body).not_to include(">投稿</a>")
    sign_in(create(:user))
    get elements_path
    expect(response.body).to include('data-action="periodic-table#post"', "data-element-post-url=\"/illustrations/new?element_id=#{element.id}\"")
    illustration = create(:illustration, element: element, monster_name: "水素の公開イラスト", published: true)
    get element_path(element)
    expect(response.body).to include("水素", "Hydrogen", "気体", "水素の公開イラスト", "ILLUSTRATIONS", 'data-turbo="false"')
    expect(response.body).to include(illustration.element.symbol)
    expect(response.body).not_to include("作品数", "水素のイラスト")
  end
end
