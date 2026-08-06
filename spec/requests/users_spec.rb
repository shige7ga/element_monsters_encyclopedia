require "rails_helper"
require "cgi"

RSpec.describe "Users", type: :request do
  it "未ログイン時のマイページはログイン画面へリダイレクトする" do
    get mypage_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "未ログイン時の共通ヘッダーに認証用ナビゲーションを表示する" do
    get root_path

    expect(response.body).to include(
      'header data-turbo="false"',
      'nav aria-label="メインナビゲーション"',
      "ユーザー登録",
      "ログイン",
      "図鑑を見る",
      'data-navigation-target="button"',
      'data-navigation-target="menu"',
      'id="login_modal"',
      'id="registration_modal"',
      'alt="水素くん"',
      'alt="ヘリウムウィッチ"',
      'alt="リチウムゴーレム"',
      "元素モンスターズ",
      'href="/assets/application-'
    )
    expect(response.body).not_to include("application.tailwind.css", "/assets/tailwindcss")
  end

  it "ログイン時のトップ画面はマイページへリダイレクトする" do
    sign_in(create(:user))

    get root_path

    expect(response).to redirect_to(mypage_path)
    follow_redirect!
    expect(response.body).to include("マイページ", "図鑑を見る", "イラスト投稿", "ログアウト")
    expect(response.body).not_to include(">周期表</a>")
  end

  it "ユーザー登録後にマイページへリダイレクトする" do
    post user_registration_path, params: { user: attributes_for(:user) }

    expect(response).to redirect_to(mypage_path)
  end

  it "ユーザーIDでログイン後にマイページを表示する" do
    user = create(:user, user_id: "login_user")

    post user_session_path, params: { user: { login: user.user_id, password: "password123" } }

    expect(response).to redirect_to(mypage_path)
    follow_redirect!
    expect(response.body).to include("マイページ", 'name="turbo-visit-control" content="reload"')
  end

  it "登録フォームのTurbo Frameとパスワード条件を表示する" do
    get new_user_registration_path, headers: { "Turbo-Frame" => "registration_modal" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('turbo-frame id="registration_modal"', "パスワードは")
  end

  it "登録エラーをモーダル内の各入力欄に表示する" do
    post user_registration_path, params: { user: {} }, headers: { "Turbo-Frame" => "registration_modal" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('turbo-frame id="registration_modal"')
    expect(response.body.scan("text-rose-600").length).to be >= 3
  end

  it "ログイン失敗時のエラーをモーダル内に表示する" do
    post user_session_path,
         params: { user: { login: "unknown_user", password: "password123" } },
         headers: { "Turbo-Frame" => "login_modal" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(CGI.unescapeHTML(response.body)).to include('role="alert"', "Invalid login or password.")
  end

  it "ログインの空欄エラーを各入力欄の下に表示する" do
    post user_session_path,
         params: { user: { login: "", password: "" } },
         headers: { "Turbo-Frame" => "login_modal" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(CGI.unescapeHTML(response.body)).to include(
      "Email or user ID can't be blank",
      "Password can't be blank"
    )
    expect(response.body).not_to include('role="alert"')
  end

  it "メールアドレスとユーザーIDの重複エラーを各欄に表示する" do
    user = create(:user)

    post user_registration_path,
         params: {
           user: {
             user_id: user.user_id,
             email: user.email,
             password: "password123",
             password_confirmation: "password123"
           }
         },
         headers: { "Turbo-Frame" => "registration_modal" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('turbo-frame id="registration_modal"')
    expect(response.body.scan("text-rose-600").length).to be >= 2
  end
end
