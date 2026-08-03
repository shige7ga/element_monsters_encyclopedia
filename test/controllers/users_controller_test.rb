require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "未ログインではマイページにアクセスできない" do
    get mypage_url

    assert_redirected_to new_user_session_url
  end

  test "未ログイン時は共通ヘッダーに認証用ナビゲーションを表示する" do
    get root_url

    assert_select 'nav[aria-label="メインナビゲーション"]' do
      assert_select "button", "ユーザー登録"
      assert_select "button", "ログイン"
      assert_select "a", "図鑑を見る"
    end
    assert_select 'button[data-navigation-target="button"]'
    assert_select 'nav[data-navigation-target="menu"]'
    assert_select 'dialog[data-modal-source="/users/sign_in"] turbo-frame#login_modal:not([src])'
    assert_select 'dialog[data-modal-source="/users/sign_up"] turbo-frame#registration_modal:not([src])'
    assert_select 'img[alt="水素くん"]'
    assert_select 'img[alt="ヘリウムウィッチ"]'
    assert_select 'img[alt="リチウムゴーレム"]'
  end

  test "ログイン時は共通ヘッダーに会員用ナビゲーションを表示する" do
    sign_in users(:one)

    get root_url

    assert_select 'nav[aria-label="メインナビゲーション"]' do
      assert_select "a", "図鑑を見る"
      assert_select "a", "周期表"
      assert_select "a", "マイページ"
      assert_select "form button", "ログアウト"
    end
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
    assert_select %q(meta[name="turbo-visit-control"][content="reload"])
  end

  test "登録フォームはパスワード条件を表示する" do
    get new_user_registration_url, headers: { "Turbo-Frame" => "registration_modal" }

    assert_response :success
    assert_select "turbo-frame#registration_modal"
    assert_select "p", /パスワードは/
  end

  test "登録エラーはモーダル内に表示される" do
    post user_registration_url, params: { user: {} }, headers: { "Turbo-Frame" => "registration_modal" }

    assert_response :unprocessable_entity
    assert_select "turbo-frame#registration_modal"
    assert_select ".text-rose-600", minimum: 3
  end

  test "ログインエラーはモーダル内に表示される" do
    post user_session_url, params: { user: { login: "unknown_user", password: "password123" } }, headers: { "Turbo-Frame" => "login_modal" }

    assert_response :unprocessable_entity
    assert_select "turbo-frame#login_modal"
    assert_select "p[role=alert]", /Invalid login or password./
  end

  test "ログインの空欄エラーは各入力欄の下に表示される" do
    post user_session_url, params: { user: { login: "", password: "" } }, headers: { "Turbo-Frame" => "login_modal" }

    assert_response :unprocessable_entity
    assert_select "p.text-rose-600", /Email or user ID can.t be blank/
    assert_select "p.text-rose-600", /Password can.t be blank/
    assert_select "p[role=alert]", count: 0
  end

  test "メールアドレスとユーザーIDの重複エラーは各欄に表示される" do
    user = users(:one)

    post user_registration_url, params: { user: { user_id: user.user_id, email: user.email, password: "password123", password_confirmation: "password123" } }, headers: { "Turbo-Frame" => "registration_modal" }

    assert_response :unprocessable_entity
    assert_select "turbo-frame#registration_modal"
    assert_select ".text-rose-600", { minimum: 2 }
  end
end
