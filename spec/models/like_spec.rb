require "rails_helper"

RSpec.describe Like, type: :model do
  it "ユーザーとイラストがあれば有効である" do
    expect(build(:like)).to be_valid
  end

  it "同じユーザーが同じイラストに重複していいねできない" do
    like = create(:like)
    duplicate_like = build(:like, user: like.user, illustration: like.illustration)

    expect(duplicate_like).not_to be_valid
    expect(duplicate_like.errors[:user_id]).to include("has already been taken")
  end

  it "イラストを削除すると関連するいいねも削除される" do
    like = create(:like)

    expect { like.illustration.destroy! }.to change(described_class, :count).by(-1)
  end

  it "ユーザーを削除すると関連するいいねも削除される" do
    like = create(:like)

    expect { like.user.destroy! }.to change(described_class, :count).by(-1)
  end
end
