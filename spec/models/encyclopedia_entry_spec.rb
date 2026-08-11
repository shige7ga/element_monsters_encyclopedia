require "rails_helper"

RSpec.describe EncyclopediaEntry, type: :model do
  let(:user) { create(:user) }
  let(:element) { create(:element) }
  let(:illustration) { create(:illustration, element: element, published: true) }

  it "ユーザー、元素、公開済みの同一元素イラストがあれば有効である" do
    expect(build(:encyclopedia_entry, user: user, element: element, illustration: illustration)).to be_valid
  end

  it "同じユーザーは同じ元素を1件だけ登録できる" do
    create(:encyclopedia_entry, user: user, element: element, illustration: illustration)
    duplicate_entry = build(:encyclopedia_entry, user: user, element: element, illustration: illustration)

    expect(duplicate_entry).not_to be_valid
    expect(duplicate_entry.errors[:element_id]).to include("has already been taken")
  end

  it "別元素または非公開のイラストは登録できない" do
    other_element = create(:element)
    private_illustration = create(:illustration, element: element, published: false)

    mismatched_entry = build(:encyclopedia_entry, user: user, element: other_element, illustration: illustration)
    private_entry = build(:encyclopedia_entry, user: user, element: element, illustration: private_illustration)

    expect(mismatched_entry).not_to be_valid
    expect(mismatched_entry.errors[:illustration]).to include("は選択した元素のイラストにしてください")
    expect(private_entry).not_to be_valid
    expect(private_entry.errors[:illustration]).to include("は公開済みのものを選択してください")
  end
end
