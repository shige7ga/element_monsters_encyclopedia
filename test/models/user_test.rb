require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "メールアドレスまたはユーザーIDで同じユーザーを取得できる" do
    user = User.create!(name: "テスト太郎", user_id: "element_hero", email: "hero@example.test", password: "password123", password_confirmation: "password123")

    assert_equal user, User.find_for_database_authentication(login: "hero@example.test")
    assert_equal user, User.find_for_database_authentication(login: "ELEMENT_HERO")
  end

  test "user_idは重複登録できない" do
    User.create!(user_id: "element_hero", email: "hero@example.test", password: "password123", password_confirmation: "password123")
    duplicate = User.new(user_id: "element_hero", email: "other@example.test", password: "password123", password_confirmation: "password123")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end
end
