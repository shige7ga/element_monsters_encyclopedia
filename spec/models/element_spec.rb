require "rails_helper"
RSpec.describe Element, type: :model do
  it "原子番号と元素記号の重複を許可しない" do
    create(:element, atomic_number: 1_000, symbol: "T1000")
    duplicate = build(:element, atomic_number: 1_000, symbol: "T1000")
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:atomic_number]).to include("has already been taken")
    expect(duplicate.errors[:symbol]).to include("has already been taken")
  end
end
