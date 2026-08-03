require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "未ログインではマイページにアクセスできない" do
    get mypage_url

    assert_redirected_to new_user_session_url
  end

  test "ユーザー登録後にマイページへ遷移する" do
    post user_registration_url, params: { user: { name: "登録太郎", user_id: "registered_user", email: "registered@example.test", password: "password123", password_confirmation: "password123" } }

    assert_redirected_to mypage_url
  end

  test "ログイン後にマイページへ遷移する" do
    user = User.create!(name: "ログイン太郎", user_id: "login_user", email: "login@example.test", password: "password123", password_confirmation: "password123")

    post user_session_url, params: { user: { login: user.user_id, password: "password123" } }

    assert_redirected_to mypage_url
    follow_redirect!
    assert_response :success
    assert_select "h1", "マイページ"
  end
end
