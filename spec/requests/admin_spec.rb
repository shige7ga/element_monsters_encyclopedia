require "rails_helper"

RSpec.describe "Admin", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:general_user) { create(:user) }

  it "未ログイン時は管理画面の各ページへアクセスできずトップへ戻る" do
    [ admin_root_path, admin_users_path, admin_illustrations_path ].each do |path|
      get path

      expect(response).to redirect_to(root_path)
    end
  end

  it "一般ユーザーは管理画面の各ページへアクセスできない" do
    sign_in(general_user)

    [ admin_root_path, admin_users_path, admin_illustrations_path ].each do |path|
      get path

      expect(response).to redirect_to(root_path)
    end
  end

  it "Adminは管理画面トップ、ユーザー一覧、イラスト一覧を閲覧できる" do
    illustration = create(:illustration)
    sign_in(admin)

    get admin_root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("管理画面", "ユーザー一覧を見る", "イラスト一覧を見る")

    get admin_users_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("ユーザー一覧", admin.user_id, "Admin")

    get admin_illustrations_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("イラスト一覧", illustration.monster_name, illustration.element.symbol)
  end

  it "管理画面へのリンクはAdminだけに表示する" do
    sign_in(general_user)

    get mypage_path
    expect(response.body).not_to include("管理画面")

    sign_out(general_user)
    sign_in(admin)

    get mypage_path
    expect(response.body).to include("管理画面", 'href="/admin"')
  end

  it "一般ユーザー登録ではadmin権限を変更できない" do
    attributes = attributes_for(:user).merge(admin: true)

    post user_registration_path, params: { user: attributes }

    expect(User.find_by!(email: attributes[:email])).not_to be_admin
  end
end
