class Illustration < ApplicationRecord
  MAX_IMAGE_SIZE = 5.megabytes
  ALLOWED_IMAGE_TYPES = %w[image/jpeg image/png image/webp].freeze

  belongs_to :user
  belongs_to :element
  has_one_attached :image
  has_many :likes
  has_many :encyclopedia_entries

  validates :user_id, :element_id, :monster_name, presence: true
  validates :published, inclusion: { in: [ true, false ] }
  validate :image_is_attached
  validate :image_content_type
  validate :image_size

  scope :published, -> { where(published: true) }
  scope :visible_to, ->(viewer) { viewer ? published.or(where(user: viewer)) : published }

  def viewable_by?(viewer)
    published? || user == viewer
  end

  private

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
