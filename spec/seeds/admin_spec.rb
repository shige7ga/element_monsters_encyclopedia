require "rails_helper"

RSpec.describe "Admin seed" do
  let(:admin_email) { "admin@example.test" }
  let(:admin_password) { "admin-password123" }

  before do
    allow(Rails.application.credentials).to receive(:dig).with(:admin, :email).and_return(admin_email)
    allow(Rails.application.credentials).to receive(:dig).with(:admin, :password).and_return(admin_password)
  end

  def load_seeds
    Object.send(:remove_const, :ELEMENTS) if Object.const_defined?(:ELEMENTS)
    load Rails.root.join("db/seeds.rb")
  end

  it "未登録の管理者を作成し、再実行しても既存Adminのパスワードを変更しない" do
    expect { load_seeds }.to change { User.where(email: admin_email).count }.by(1)

    admin_user = User.find_by!(email: admin_email)
    encrypted_password = admin_user.encrypted_password
    expect(admin_user).to be_admin

    expect { load_seeds }.not_to change(User, :count)
    expect(admin_user.reload.encrypted_password).to eq(encrypted_password)
  end

  it "同一メールアドレスの一般ユーザーを自動昇格させずエラーにする" do
    general_user = create(:user, email: admin_email)

    expect { load_seeds }.to raise_error(
      RuntimeError,
      "同一メールアドレスの一般ユーザーが存在するため、管理者を作成できません。"
    )
    expect(general_user.reload).not_to be_admin
  end
end
