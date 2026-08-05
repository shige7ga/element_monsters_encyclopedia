FactoryBot.define do
  factory :element do
    sequence(:atomic_number) { |number| number + 1_000 }
    sequence(:symbol) { |number| "T#{number}" }
    name { "テスト元素" }
    english_name { "Test Element" }
    common_state { "固体" }
    description { "テスト用の元素です。" }
    period { 1 }
    group_number { 1 }
  end
end
