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
      "学習する",
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
    expect(response.body).to include("マイページ", "図鑑を見る", "学習する", "イラスト投稿", "推し元素図鑑", "ログアウト")
    expect(response.body).to include('href="/encyclopedia_entries"')
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
    expect(response.body).to include('<turbo-frame', 'id="registration_modal"', "パスワード", "文字以上で入力してください")
  end

  it "登録エラーをモーダル内の各入力欄に表示する" do
    post user_registration_path, params: { user: {} }, headers: { "Turbo-Frame" => "registration_modal" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('<turbo-frame', 'id="registration_modal"')
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
    expect(response.body).to include('<turbo-frame', 'id="registration_modal"')
    expect(response.body.scan("text-rose-600").length).to be >= 2
  end

  it "マイページでは投稿一覧といいね一覧を切り替えられる" do
    user = create(:user, name: "マイページユーザー")
    element = create(:element)
    posted_illustration = create(:illustration, user: user, element: element, monster_name: "自分の投稿")
    liked_illustration = create(:illustration, element: element, monster_name: "自分がいいねした投稿")
    create(:like, user: user, illustration: liked_illustration)
    sign_in(user)

    get mypage_path
    expect(response.body).to include("あなたの投稿", posted_illustration.monster_name, "投稿一覧", "いいね一覧", "イラスト投稿")
    expect(response.body).not_to include(liked_illustration.monster_name)

    get mypage_path(tab: "likes")
    expect(response.body).to include("あなたのいいね一覧", liked_illustration.monster_name)
    expect(response.body).not_to include(posted_illustration.monster_name)
  end

  it "他ユーザーのページでも投稿一覧と公開いいね一覧を切り替えられる" do
    user = create(:user, name: "投稿者")
    element = create(:element)
    posted_illustration = create(:illustration, user: user, element: element, monster_name: "投稿者の投稿")
    liked_illustration = create(:illustration, element: element, monster_name: "投稿者がいいねした投稿")
    create(:like, user: user, illustration: liked_illustration)

    get user_path(user)
    expect(response.body).to include("投稿者さんの投稿", posted_illustration.monster_name)
    expect(response.body).not_to include(liked_illustration.monster_name)

    get user_path(user, tab: "likes")
    expect(response.body).to include("投稿者さんのいいね一覧", liked_illustration.monster_name)
    expect(response.body).not_to include(posted_illustration.monster_name)
  end
end
