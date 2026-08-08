FactoryBot.define do
  factory :like do
    association :user
    association :illustration
  end
end
