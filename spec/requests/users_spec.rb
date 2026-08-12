require "rails_helper"
require "cgi"
require "nokogiri"

RSpec.describe "Users", type: :request do
  it "未ログイン時のマイページはログイン画面へリダイレクトする" do
    get mypage_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "未ログイン時の共通ヘッダーに認証用ナビゲーションを表示する" do
    get root_path

    expect(response.body).to include(
      'header data-turbo="false"',
      'fixed inset-x-0 top-0 z-50',
      'pt-[68px] sm:pt-[72px]',
      'href="/illustrations"',
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
      "学びと創造がつながる空間",
      "見つかる、推し元素。",
      "「覚える」から「好きになる」へ。",
      'href="/illustrations"',
      'href="/assets/application-'
    )
    expect(response.body).not_to include("application.tailwind.css", "/assets/tailwindcss")
  end

  it "未ログイン時のヘッダーロゴはトップへ遷移し、通常ナビゲーションは透明背景で表示する" do
    get root_path

    header = Nokogiri::HTML(response.body).at_css("header")
    logo_link = header.css("a").find { |link| link.at_css('img[alt="元素モンスターズ図鑑LOGO"]') }
    catalog_link = header.css("a").find { |link| link.text.strip == "図鑑を見る" }

    expect(logo_link["href"]).to eq(root_path)
    expect(catalog_link["class"]).to include("border-cyan-300", "bg-transparent", "text-cyan-300")
    expect(header.text).not_to include("推し元素図鑑")
  end

  it "ログイン時のヘッダーロゴはイラスト一覧へ遷移し、表示中の導線を強調する" do
    user = create(:user)
    sign_in(user)

    get illustrations_path

    header = Nokogiri::HTML(response.body).at_css("header")
    logo_link = header.css("a").find { |link| link.at_css('img[alt="元素モンスターズ図鑑LOGO"]') }
    catalog_link = header.css("a").find { |link| link.text.strip == "図鑑を見る" }
    learning_link = header.css("a").find { |link| link.text.strip == "学習する" }
    post_link = header.css("a").find { |link| link.text.strip == "投稿する" }

    expect(logo_link["href"]).to eq(illustrations_path)
    expect(catalog_link["class"]).to include("bg-cyan-300", "text-slate-950")
    expect(learning_link["class"]).to include("bg-transparent", "text-cyan-300")
    expect(post_link["class"]).to include("bg-transparent", "text-cyan-300")
    expect(header.text).not_to include("推し元素図鑑")
  end

  it "学習・投稿画面では対応するヘッダー導線を強調する" do
    user = create(:user)
    sign_in(user)

    get learning_path
    header = Nokogiri::HTML(response.body).at_css("header")
    learning_link = header.css("a").find { |link| link.text.strip == "学習する" }
    expect(learning_link["class"]).to include("bg-cyan-300", "text-slate-950")

    get new_illustration_path
    header = Nokogiri::HTML(response.body).at_css("header")
    post_link = header.css("a").find { |link| link.text.strip == "投稿する" }
    expect(post_link["class"]).to include("bg-cyan-300", "text-slate-950")
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

  it "ユーザー登録で入力ルール違反を各項目のエラーとして表示する" do
    post user_registration_path,
         params: {
           user: {
             name: "あ" * 41,
             user_id: "invalid user id",
             email: "invalid-email",
             password: "short",
             password_confirmation: "different"
           }
         },
         headers: { "Turbo-Frame" => "registration_modal" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(CGI.unescapeHTML(response.body)).to include(
      "Name is too long",
      "ユーザーID は半角英数字、_、-のみ使用できます",
      "Email is invalid",
      "Password is too short",
      "Password confirmation doesn't match Password"
    )
  end

  it "ユーザー登録後にマイページへリダイレクトする" do
    post user_registration_path, params: { user: attributes_for(:user) }

    expect(response).to redirect_to(mypage_path)
  end

  it "マイページからユーザー情報編集ページへ移動でき、他ユーザーのページには設定ボタンを表示しない" do
    user = create(:user)
    other_user = create(:user)
    sign_in(user)

    get mypage_path
    expect(response.body).to include('href="/users/edit"', 'aria-label="ユーザー設定"', "gear_icon", "border-white")
    expect(response.body).not_to include(">ユーザー設定</a>")

    get user_path(other_user)
    expect(response.body).not_to include('aria-label="ユーザー設定"')

    get edit_user_registration_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("ユーザー情報を編集", "表示名", "ユーザーID", "メールアドレス", "現在のパスワード", "保存する")
  end

  it "マイページに本人のステータスと更新後の設定導線を表示する" do
    user = create(:user, user_id: "status_user")
    illustration = create(:illustration, user: user)
    create(:game_session, user: user, score: 6, total_questions: 10)
    create(:game_session, user: user, score: 8, total_questions: 10)
    create(:encyclopedia_entry, user: user, illustration: illustration, element: illustration.element)
    sign_in(user)

    get mypage_path

    document = Nokogiri::HTML(response.body)
    settings_link = document.at_css('a[aria-label="ユーザー設定"]')
    post_link = document.css("a").find { |link| link.text.strip == "イラスト投稿" }

    expect(settings_link["class"]).to include("border-white", "hover:border-white")
    expect(settings_link["class"]).not_to include("hover:border-cyan-300")
    expect(settings_link.at_css("img")["class"]).to include("h-7", "w-7")
    expect(post_link["class"]).to include("button-interaction", "hover:bg-cyan-300")
    expect(response.body).to include(
      "@#{user.user_id}",
      "イラスト投稿数",
      "クイズ実施回数",
      "クイズ最高点",
      "推し元素登録数",
      ">1</dd>",
      ">2</dd>",
      ">8/10</dd>"
    )
    expect(response.body).not_to include("ようこそ、")
  end

  it "ユーザー情報はログイン中の本人だけが更新できる" do
    user = create(:user, name: "変更前")
    other_user = create(:user, name: "他ユーザー")
    sign_in(user)

    patch user_registration_path,
          params: {
            user: {
              name: "変更後",
              user_id: "updated_user",
              email: user.email,
              current_password: "password123"
            }
          }

    expect(response).to redirect_to(mypage_path)
    expect(user.reload).to have_attributes(name: "変更後", user_id: "updated_user")
    expect(other_user.reload.name).to eq("他ユーザー")

    follow_redirect!
    expect(response.body).to include('role="status"', 'data-controller="flash-message"', "ユーザー情報を更新しました。")
  end

  it "ユーザー情報の更新に失敗した場合は複数の原因を表示する" do
    user = create(:user)
    duplicate_user = create(:user)
    sign_in(user)

    patch user_registration_path,
          params: {
            user: {
              name: "更新失敗",
              user_id: duplicate_user.user_id,
              email: "invalid-email",
              current_password: "password123"
            }
          }

    expect(response).to have_http_status(:unprocessable_content)
    expect(CGI.unescapeHTML(response.body)).to include(
      'id="error_explanation"',
      "入力内容を確認してください。",
      "ユーザーID has already been taken",
      "Email is invalid"
    )
  end

  it "ユーザー情報編集でもユーザーIDの形式と名前の文字数を検証する" do
    user = create(:user)
    sign_in(user)

    patch user_registration_path,
          params: {
            user: {
              name: "あ" * 41,
              user_id: "invalid user id",
              email: user.email,
              current_password: "password123"
            }
          }

    expect(response).to have_http_status(:unprocessable_content)
    expect(CGI.unescapeHTML(response.body)).to include(
      "Name is too long",
      "ユーザーID は半角英数字、_、-のみ使用できます"
    )
  end

  it "未ログイン時はユーザー情報編集ページへアクセスできない" do
    get edit_user_registration_path

    expect(response).to redirect_to(new_user_session_path)
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
    expect(response.body).to include('<turbo-frame', 'id="registration_modal"', "パスワード", "6〜32文字で入力してください")
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

  it "マイページの投稿一覧といいね一覧を10件ずつ表示する" do
    user = create(:user)
    element = create(:element)
    illustrations = 11.times.map do |index|
      create(:illustration, user: user, element: element, monster_name: "マイページ作品#{index + 1}", created_at: (index + 1).minutes.ago)
    end
    illustrations.each { |illustration| create(:like, user: user, illustration: illustration) }
    sign_in(user)

    get mypage_path(page: 2)

    expect(response.body).to include("2 / 2", "マイページ作品11")

    get mypage_path(tab: "likes", page: 2)

    expect(response.body).to include("あなたのいいね一覧", "2 / 2", "マイページ作品11")
    expect(response.body).to include('href="/mypage?page=1&amp;tab=likes"')
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
