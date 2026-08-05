require "test_helper"

class ElementsControllerTest < ActionDispatch::IntegrationTest
  test "周期表と元素詳細を表示できる" do
    get elements_url
    assert_response :success
    assert_select "h1", "元素の周期表"
    assert_select 'button[aria-label="水素の情報を表示"]'
    assert_select "button", "投稿"
    get element_url(elements(:hydrogen))
    assert_response :success
    assert_select "h1", "水素"
    assert_select "dd", /気体/
  end
end
