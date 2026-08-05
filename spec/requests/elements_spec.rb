require "rails_helper"
RSpec.describe "Elements", type: :request do
  let!(:element) { create(:element, atomic_number: 1_000, symbol: "T1000", name: "水素", english_name: "Hydrogen", common_state: "気体") }
  it "周期表と元素詳細を表示し、投稿はログイン時だけ表示する" do
    get elements_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("周期表", "水素の情報を表示")
    expect(response.body).not_to include(">投稿</button>")
    sign_in(create(:user))
    get elements_path
    expect(response.body).to include(">投稿</button>")
    get element_path(element)
    expect(response.body).to include("水素", "Hydrogen", "気体", 'data-turbo="false"')
  end
end
