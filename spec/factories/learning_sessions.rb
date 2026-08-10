FactoryBot.define do
  factory :game_session do
    association :user
    score { 8 }
    total_questions { 10 }
  end
end
