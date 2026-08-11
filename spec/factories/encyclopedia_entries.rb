FactoryBot.define do
  factory :encyclopedia_entry do
    association :user
    association :illustration
    element { illustration.element }
  end
end
