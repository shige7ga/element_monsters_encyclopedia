class User < ApplicationRecord
  attr_accessor :login

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :illustrations, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_illustrations, through: :likes, source: :illustration
  has_many :game_sessions, dependent: :destroy

  validates :user_id, presence: true, uniqueness: { case_sensitive: false }

  def self.find_for_database_authentication(warden_conditions)
    login = warden_conditions[:login].to_s.strip.downcase
    return if login.blank?

    where("LOWER(email) = :login OR LOWER(user_id) = :login", login: login).first
  end
end
