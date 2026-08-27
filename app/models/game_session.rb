class GameSession < ApplicationRecord
  belongs_to :user

  validates :score, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :total_questions, numericality: { only_integer: true, greater_than: 0 }
  validate :score_does_not_exceed_total_questions

  private

  def score_does_not_exceed_total_questions
    return if score.blank? || total_questions.blank? || score <= total_questions

    errors.add(:score, :must_not_exceed_total_questions)
  end
end
