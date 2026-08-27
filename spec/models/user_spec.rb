require "rails_helper"

RSpec.describe User, type: :model do
  it "メールアドレスまたは大文字小文字を区別しないユーザーIDで取得できる" do
    user = create(:user, user_id: "element_hero", email: "hero@example.test")

    expect(described_class.find_for_database_authentication(login: user.email)).to eq(user)
    expect(described_class.find_for_database_authentication(login: "ELEMENT_HERO")).to eq(user)
  end

  it "名前・ユーザーID・メールアドレスの前後空白を除去する" do
    user = build(:user, name: "  テストユーザー  ", user_id: "  element_hero  ", email: "  hero@example.test  ")

    expect(user).to be_valid
    expect(user).to have_attributes(name: "テストユーザー", user_id: "element_hero", email: "hero@example.test")
  end

  it "名前は空欄を許可し、40文字を超えると無効になる" do
    expect(build(:user, name: "")).to be_valid

    user = build(:user, name: "あ" * 41)
    expect(user).not_to be_valid
    expect(user.errors[:name]).to be_present
  end

  it "ユーザーIDは3〜40文字の半角英数字・アンダースコア・ハイフンだけを許可する" do
    expect(build(:user, user_id: "ab")).not_to be_valid
    expect(build(:user, user_id: "a" * 41)).not_to be_valid
    expect(build(:user, user_id: "element hero")).not_to be_valid
    expect(build(:user, user_id: "元素図鑑")).not_to be_valid
    expect(build(:user, user_id: "element_hero-01")).to be_valid
  end

  it "ユーザーIDとメールアドレスは大文字小文字を区別せず重複を許可しない" do
    create(:user, user_id: "Element_Hero", email: "Hero@Example.Test")
    duplicate = build(:user, user_id: "element_hero", email: "hero@example.test")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to include("はすでに使用されています")
    expect(duplicate.errors[:email]).to include("はすでに使用されています")
  end

  it "DBでも大文字小文字を区別しないユーザーIDの重複を拒否する" do
    user = create(:user, user_id: "Element_Hero", email: "Hero@Example.Test")

    expect do
      described_class.transaction(requires_new: true) do
        described_class.insert_all!([
          {
            user_id: "element_hero",
            email: "another@example.test",
            encrypted_password: user.encrypted_password,
            created_at: Time.current,
            updated_at: Time.current
          }
        ])
      end
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "DBでも大文字小文字を区別しないメールアドレスの重複を拒否する" do
    user = create(:user, user_id: "Element_Hero", email: "Hero@Example.Test")

    expect do
      described_class.transaction(requires_new: true) do
        described_class.insert_all!([
          {
            user_id: "another_user",
            email: "hero@example.test",
            encrypted_password: user.encrypted_password,
            created_at: Time.current,
            updated_at: Time.current
          }
        ])
      end
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "パスワードは新規登録時に必須で、6〜32文字と確認入力一致を求める" do
    expect(build(:user, password: "", password_confirmation: "")).not_to be_valid
    expect(build(:user, password: "short", password_confirmation: "short")).not_to be_valid
    expect(build(:user, password: "a" * 33, password_confirmation: "a" * 33)).not_to be_valid
    expect(build(:user, password: "password123", password_confirmation: "different123")).not_to be_valid
    expect(build(:user, password: "password123", password_confirmation: "password123")).to be_valid
  end

  it "既存ユーザーはパスワード未変更でもプロフィールを更新できる" do
    user = create(:user)
    user.name = "更新後"

    expect(user).to be_valid
  end
end
