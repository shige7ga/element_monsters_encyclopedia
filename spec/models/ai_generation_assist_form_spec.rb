require "rails_helper"

RSpec.describe AiGenerationAssistForm, type: :model do
  let(:element) do
    create(
      :element,
      name: "水素",
      symbol: "H",
      atomic_number: 1,
      english_name: "Hydrogen",
      common_state: "気体",
      description: "最も軽い元素です。"
    )
  end

  subject(:assist) do
    described_class.new(
      element_id: element.id,
      atmosphere: "幻想的",
      monster_shape: "ドラゴン型",
      main_color: "青",
      sub_color: "銀",
      motif: "騎士",
      personality: "勇敢",
      related_words: "星、雲",
      additional_request: "翼を大きくしてください"
    )
  end

  it "元素情報と入力条件から、用途別に異なる2種類のプロンプトを生成する" do
    expect(assist).to be_valid
    expect(assist.illustration_prompt).to include("水素", "H", "原子番号1", "最も軽い元素です。", "ドラゴン型", "メインカラー：青")
    expect(assist.name_prompt).to include("名前を5案", "各案について、名前と由来", "元素名・元素記号・元素の特徴・モチーフ")
    expect(assist.illustration_prompt).not_to eq(assist.name_prompt)
  end

  it "存在しない元素は受け付けない" do
    invalid_assist = described_class.new(element_id: -1)

    expect(invalid_assist).not_to be_valid
    expect(invalid_assist.errors[:element_id]).to include("は存在する元素を選択してください")
  end
end
