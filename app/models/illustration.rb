class Illustration < ApplicationRecord
  MAX_IMAGE_SIZE = 5.megabytes
  ALLOWED_IMAGE_TYPES = %w[image/jpeg image/png image/webp].freeze

  belongs_to :user
  belongs_to :element
  has_one_attached :image
  has_many :likes, dependent: :destroy
  has_many :liked_by_users, through: :likes, source: :user
  has_many :encyclopedia_entries, dependent: :destroy

  enum :creation_type, { self_made: "self_made", ai_generated: "ai_generated" }, validate: { message: "は自作またはAI生成を選択してください" }

  before_validation :normalize_text_attributes

  validates :user_id, presence: true
  validates :element_id, presence: { message: "を選択してください" }
  validates :creation_type, presence: { message: "を選択してください" }
  validates :monster_name, length: { maximum: 40, message: "は40文字以内で入力してください" }, allow_blank: true
  validates :description, length: { maximum: 1000, message: "は1000文字以内で入力してください" }, allow_blank: true
  validates :published, inclusion: { in: [ true, false ], message: "は公開または非公開を選択してください" }
  validate :published_value_is_boolean
  validate :image_is_attached
  validate :image_content_type
  validate :image_size

  scope :published, -> { where(published: true) }
  scope :visible_to, ->(viewer) { viewer ? published.or(where(user: viewer)) : published }
  scope :popular, -> { left_joins(:likes).group(:id).order(Arel.sql("COUNT(likes.id) DESC"), created_at: :desc) }

  def liked_by?(viewer)
    return false unless viewer

    likes.loaded? ? likes.any? { |like| like.user_id == viewer.id } : likes.exists?(user: viewer)
  end

  def viewable_by?(viewer)
    published? || user == viewer
  end

  private

  # 空白だけの入力を空欄として扱い、保存前に前後の空白を除去する
  def normalize_text_attributes
    self.monster_name = monster_name.to_s.strip
    self.description = description&.strip.presence
  end

  # Railsのboolean型変換で任意文字列がtrueになることを防ぐ
  def published_value_is_boolean
    return if [ true, false, 0, 1, "0", "1", "true", "false" ].include?(published_before_type_cast)

    errors.add(:published, "は公開または非公開の値を選択してください")
  end

  def image_is_attached
    errors.add(:image, "を添付してください") unless image.attached?
  end

  def image_content_type
    return unless image.attached?
    return if image.content_type.in?(ALLOWED_IMAGE_TYPES)

    errors.add(:image, "はJPEG、PNG、WebP形式にしてください")
  end

  def image_size
    return unless image.attached?
    return if image.byte_size <= MAX_IMAGE_SIZE

    errors.add(:image, "は5MB以下にしてください")
  end
end
