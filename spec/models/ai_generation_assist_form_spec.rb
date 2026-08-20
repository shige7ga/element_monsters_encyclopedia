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
      motif: "騎士",
      personality: "勇敢",
      additional_request: "翼を大きくしてください"
    )
  end

  it "元素情報と入力条件から、用途別に異なる2種類のプロンプトを生成する" do
    expect(assist).to be_valid
    expect(assist.illustration_prompt).to include(
      "水素",
      "H",
      "原子番号1",
      "最も軽い元素です。",
      "ドラゴン型",
      "メインカラー：青",
      "元素名・原子番号・英名・常温での状態・元素の説明文を画像内に文字として描画しないでください",
      "元素記号は、紋章・装飾・鎧・持ち物・球体などデザインの一部に自然に組み込んでも構いませんが、使用は必須ではありません",
      "著作権・商標権・肖像権など第三者の権利を侵害せず",
      "特定のクリエイターの作品そのものを再現したり",
      "過度に暴力的、残虐、グロテスク、性的、その他刺激の強すぎる表現は避け"
    )
    expect(assist.name_prompt).to include("名前を5案", "各案について、名前と由来", "元素名・元素記号・元素の特徴・モチーフ", "キーワード・こだわり：翼を大きくしてください")
    expect(assist.illustration_prompt).to include("- 雰囲気：幻想的\n- モンスターの形：ドラゴン型")
    expect(assist.illustration_prompt).not_to include('["- 雰囲気')
    expect(assist.illustration_prompt).not_to eq(assist.name_prompt)
  end

  it "かんたんアシスト用の選択肢からその他を除外する" do
    expect(described_class::ATMOSPHERE_OPTIONS).not_to include("その他")
    expect(described_class::MONSTER_SHAPE_OPTIONS).not_to include("その他")
    expect(described_class::MOTIF_OPTIONS).not_to include("その他")
    expect(described_class::PERSONALITY_OPTIONS).to include("勇敢", "いたずら好き")
    expect(described_class::MAIN_COLOR_OPTIONS).to eq(%w[赤 青 緑 黄 紫 白 黒 金])
  end

  it "存在しない元素は受け付けない" do
    invalid_assist = described_class.new(element_id: -1)

    expect(invalid_assist).not_to be_valid
    expect(invalid_assist.errors[:element_id]).to include("は存在する元素を選択してください")
  end
end
