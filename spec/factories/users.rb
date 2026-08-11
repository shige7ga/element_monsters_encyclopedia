FactoryBot.define do
  factory :user do
    sequence(:user_id) { |number| "element_user_#{number}" }
    sequence(:email) { |number| "user_#{number}@example.test" }
    name { "テストユーザー" }
    password { "password123" }
    password_confirmation { "password123" }

    trait :admin do
      admin { true }
    end
  end
end
