require "rails_helper"
RSpec.describe User, type: :model do
  it "メールアドレスまたは大文字小文字を区別しないユーザーIDで取得できる" do
    user = create(:user, user_id: "element_hero", email: "hero@example.test")
    expect(described_class.find_for_database_authentication(login: user.email)).to eq(user)
    expect(described_class.find_for_database_authentication(login: "ELEMENT_HERO")).to eq(user)
  end
  it "user_idの重複を許可しない" do
    create(:user, user_id: "element_hero")
    duplicate = build(:user, user_id: "element_hero")
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to include("has already been taken")
  end
end
