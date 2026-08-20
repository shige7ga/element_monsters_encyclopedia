class AiGenerationAssistForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  ATMOSPHERE_OPTIONS = %w[リアル アニメ ポップ かわいい ダーク 幻想的 神秘的].freeze
  MONSTER_SHAPE_OPTIONS = %w[人型 ゴーレム型 獣型 スライム型 鳥型 ドラゴン型 植物型].freeze
  MAIN_COLOR_OPTIONS = %w[赤 青 緑 黄 紫 白 黒 金].freeze
  MOTIF_OPTIONS = %w[騎士 魔法使い ロボット 妖精 神 悪魔 武士].freeze
  PERSONALITY_OPTIONS = %w[勇敢 温厚 元気 冷静 凶暴 神秘的 いたずら好き].freeze

  attribute :element_id, :integer
  attribute :atmosphere, :string
  attribute :monster_shape, :string
  attribute :main_color, :string
  attribute :motif, :string
  attribute :personality, :string
  attribute :additional_request, :string

  validates :element_id, presence: { message: "を選択してください" }
  validate :element_must_exist

  def element
    @element ||= Element.find_by(id: element_id)
  end

  # 選択・入力内容を画像生成AIへそのまま渡せる日本語の依頼文へ整形する。
  def illustration_prompt
    <<~PROMPT.strip
      以下の元素をモチーフにした、オリジナルの元素モンスターを1体デザインしたイラストを作成してください。

      #{element_information}
      デザイン条件：
      #{design_conditions}

      上記の元素情報は、画像に書く情報ではなく、モンスターデザインを考えるための参考情報です。元素名・原子番号・英名・常温での状態・元素の説明文を画像内に文字として描画しないでください。元素の特徴は文字で説明せず、見た目・色・質感・装備・能力を想起させる表現・背景・モチーフなどの視覚表現として反映してください。元素記号は、紋章・装飾・鎧・持ち物・球体などデザインの一部に自然に組み込んでも構いませんが、使用は必須ではありません。

      著作権・商標権・肖像権など第三者の権利を侵害せず、既存キャラクター、既存作品、ロゴ、実在人物などを無断で再現しない、オリジナルのモンスターデザインにしてください。特定のクリエイターの作品そのものを再現したり、特定クリエイターの作風を意図的に模倣することを目的としたデザインにはしないでください。過度に暴力的、残虐、グロテスク、性的、その他刺激の強すぎる表現は避け、幅広いユーザーが閲覧できるモンスターデザインにしてください。
    PROMPT
  end

  # モンスター名の案出し専用に、イラスト生成とは分けた依頼文を生成する。
  def name_prompt
    <<~PROMPT.strip
      次の元素モンスターにふさわしい名前を5案提案してください。各案について、名前と由来を1〜2文で説明してください。

      #{element_information}
      デザイン条件：
      #{design_conditions}

      元素名・元素記号・元素の特徴・モチーフを名前や由来に反映し、覚えやすく、元素モンスターとして使いやすいオリジナルの名前にしてください。
    PROMPT
  end

  private

  def element_must_exist
    return if element_id.blank? || element.present?

    errors.add(:element_id, "は存在する元素を選択してください")
  end

  def element_information
    "元素情報：元素名「#{element.name}」、元素記号「#{element.symbol}」、原子番号#{element.atomic_number}、英名「#{element.english_name}」、常温での状態「#{element.common_state}」。\n元素の特徴：#{element.description.presence || "元素の性質を活かしてください。"}"
  end

  def design_conditions
    conditions = {
      "雰囲気" => atmosphere,
      "モンスターの形" => monster_shape,
      "メインカラー" => main_color,
      "モチーフ" => motif,
      "印象・性格" => personality,
      "キーワード・こだわり" => additional_request
    }

    conditions.filter_map do |label, value|
      "- #{label}：#{value.strip}" if value.present?
    end.join("\n").presence || "- 特に指定なし。元素の特徴から提案してください。"
  end
end
