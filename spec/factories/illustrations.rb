require "stringio"

FactoryBot.define do
  factory :illustration do
    association :user
    association :element
    sequence(:monster_name) { |number| "元素モンスター作品 #{number}" }
    description { "元素を楽しく学ぶためのイラストです。" }
    published { true }

    after(:build) do |illustration|
      illustration.image.attach(
        io: StringIO.new("test image"),
        filename: "illustration.png",
        content_type: "image/png"
      )
    end
  end
end
