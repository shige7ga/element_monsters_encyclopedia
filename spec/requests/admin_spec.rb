require "rails_helper"

RSpec.describe "Admin", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:general_user) { create(:user) }
  let(:managed_user) { create(:user) }
  let(:illustration) { create(:illustration, user: managed_user) }

  it "未ログイン時は管理画面の各ページへアクセスできずトップへ戻る" do
    [
      admin_root_path,
      admin_users_path,
      admin_user_path(managed_user),
      admin_illustrations_path,
      admin_illustration_path(illustration)
    ].each do |path|
      get path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_nil
    end
  end

  it "一般ユーザーは管理画面の各ページや管理操作へアクセスできない" do
    sign_in(general_user)

    [
      admin_root_path,
      admin_users_path,
      admin_user_path(managed_user),
      admin_illustrations_path,
      admin_illustration_path(illustration)
    ].each do |path|
      get path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("管理画面へのアクセス権限がありません。")
    end

    expect { delete admin_user_path(managed_user) }.not_to change(User, :count)
    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq("管理画面へのアクセス権限がありません。")

    expect { patch toggle_published_admin_illustration_path(illustration) }.not_to change { illustration.reload.published? }
    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq("管理画面へのアクセス権限がありません。")

    expect { delete admin_illustration_path(illustration) }.not_to change(Illustration, :count)
    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq("管理画面へのアクセス権限がありません。")
  end

  it "Adminはダッシュボード、ユーザー詳細、イラスト詳細を閲覧できる" do
    illustration
    sign_in(admin)

    get admin_root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("管理画面", "ユーザー一覧を見る", "イラスト一覧を見る", User.count.to_s, Illustration.count.to_s)

    get admin_users_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("ユーザー一覧", admin.user_id, "Admin", "詳細", "削除")

    get admin_user_path(managed_user)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(managed_user.user_id, "投稿一覧", "ユーザーを削除")

    get admin_illustrations_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("イラスト一覧", illustration.monster_name, illustration.element.symbol, "詳細", "削除")

    get admin_illustration_path(illustration)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(illustration.monster_name, "公開中", "非公開にする", "削除")
  end

  it "Adminはユーザーを削除できる" do
    managed_user
    sign_in(admin)

    expect { delete admin_user_path(managed_user) }.to change(User, :count).by(-1)
    expect(response).to redirect_to(admin_users_path)
  end

  it "Adminはイラストを削除できる" do
    illustration
    sign_in(admin)

    expect { delete admin_illustration_path(illustration) }.to change(Illustration, :count).by(-1)
    expect(response).to redirect_to(admin_illustrations_path)
  end

  it "Adminはイラストの公開状態を切り替えられる" do
    illustration
    sign_in(admin)

    expect { patch toggle_published_admin_illustration_path(illustration) }
      .to change { illustration.reload.published? }.from(true).to(false)
    expect(response).to redirect_to(admin_illustration_path(illustration))

    expect { patch toggle_published_admin_illustration_path(illustration) }
      .to change { illustration.reload.published? }.from(false).to(true)
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
