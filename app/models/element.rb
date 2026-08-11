class Element < ApplicationRecord
  has_many :illustrations, dependent: :destroy
  has_many :encyclopedia_entries, dependent: :destroy

  validates :atomic_number, presence: true, uniqueness: true, numericality: { only_integer: true, greater_than: 0 }
  validates :symbol, presence: true, uniqueness: true
  validates :name, :english_name, :common_state, :period, presence: true
  validates :period, numericality: { only_integer: true, in: 1..7 }
  validates :group_number, numericality: { only_integer: true, in: 1..18 }, allow_nil: true
end
