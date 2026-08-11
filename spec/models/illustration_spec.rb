require "rails_helper"
require "stringio"

RSpec.describe Illustration, type: :model do
  let(:user) { create(:user) }
  let(:element) { create(:element) }

  it "ユーザー、元素、モンスター名、画像があれば有効である" do
    illustration = build(:illustration, user: user, element: element)

    expect(illustration).to be_valid
  end

  it "画像がなければ無効である" do
    illustration = described_class.new(user: user, element: element, monster_name: "画像なし")

    expect(illustration).not_to be_valid
    expect(illustration.errors[:image]).to include("を添付してください")
  end

  it "許可されていない画像形式を拒否する" do
    illustration = described_class.new(user: user, element: element, monster_name: "形式エラー")
    illustration.image.attach(io: StringIO.new("text"), filename: "text.txt", content_type: "text/plain")

    expect(illustration).not_to be_valid
    expect(illustration.errors[:image]).to include("はJPEG、PNG、WebP形式にしてください")
  end

  it "5MBを超える画像を拒否する" do
    illustration = described_class.new(user: user, element: element, monster_name: "容量エラー")
    illustration.image.attach(
      io: StringIO.new("a" * (described_class::MAX_IMAGE_SIZE + 1)),
      filename: "large.png",
      content_type: "image/png"
    )

    expect(illustration).not_to be_valid
    expect(illustration.errors[:image]).to include("は5MB以下にしてください")
  end

  it "作成方法は自作またはAI生成のみ許可する" do
    expect(build(:illustration, user: user, element: element, creation_type: "self_made")).to be_valid
    expect(build(:illustration, user: user, element: element, creation_type: "ai_generated")).to be_valid
    expect(build(:illustration, user: user, element: element, creation_type: "unknown")).not_to be_valid
    expect(build(:illustration, user: user, element: element, creation_type: nil)).not_to be_valid
  end

  it "公開作品と閲覧者本人の非公開作品だけを返す" do
    published = create(:illustration, user: user, element: element, published: true)
    private_illustration = create(:illustration, user: user, element: element, published: false)
    other_private = create(:illustration, published: false)

    expect(described_class.visible_to(nil)).to contain_exactly(published)
    expect(described_class.visible_to(user)).to contain_exactly(published, private_illustration)
    expect(described_class.visible_to(other_private.user)).to contain_exactly(published, other_private)
  end

  it "人気順ではいいね数が多い作品を先に返す" do
    popular_illustration = create(:illustration, user: user, element: element)
    less_popular_illustration = create(:illustration, user: user, element: element)
    create_list(:like, 2, illustration: popular_illustration)
    create(:like, illustration: less_popular_illustration)

    expect(described_class.popular).to start_with(popular_illustration)
  end
end
