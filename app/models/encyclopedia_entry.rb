class EncyclopediaEntry < ApplicationRecord
  belongs_to :user
  belongs_to :element
  belongs_to :illustration

  validates :user, :element, :illustration, presence: true
  validates :element_id, uniqueness: { scope: :user_id }
  validate :illustration_matches_element
  validate :illustration_is_published

  private

  def illustration_matches_element
    return if element.blank? || illustration.blank? || illustration.element_id == element_id

    errors.add(:illustration, "は選択した元素のイラストにしてください")
  end

  def illustration_is_published
    return if illustration.blank? || illustration.published?

    errors.add(:illustration, "は公開済みのものを選択してください")
  end
end
