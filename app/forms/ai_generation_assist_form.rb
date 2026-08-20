class AiGenerationAssistForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  ATMOSPHERE_OPTIONS = %w[リアル アニメ ポップ かわいい ダーク 幻想的 神秘的 その他].freeze
  MONSTER_SHAPE_OPTIONS = %w[人型 ゴーレム型 獣型 スライム型 鳥型 ドラゴン型 植物型 その他].freeze
  MOTIF_OPTIONS = %w[騎士 魔法使い ロボット 妖精 神 悪魔 武士 その他].freeze

  attribute :element_id, :integer
  attribute :atmosphere, :string
  attribute :monster_shape, :string
  attribute :main_color, :string
  attribute :sub_color, :string
  attribute :motif, :string
  attribute :personality, :string
  attribute :related_words, :string
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

      元素の性質や特徴を、モンスターの外見・質感・能力・配色に自然に反映してください。見ただけで元素らしさが伝わる、魅力的で独創的なキャラクターデザインにしてください。既存の作品・キャラクター・実在人物・ロゴ・特定の作家の作風を模倣せず、オリジナルの表現にしてください。
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
      "サブカラー" => sub_color,
      "モチーフ" => motif,
      "印象・性格" => personality,
      "関連ワード" => related_words,
      "こだわり・追加要望" => additional_request
    }

    conditions.filter_map do |label, value|
      "- #{label}：#{value.strip}" if value.present?
    end.presence || "- 特に指定なし。元素の特徴から提案してください。"
  end
end
