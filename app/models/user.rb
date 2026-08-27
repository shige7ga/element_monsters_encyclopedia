class User < ApplicationRecord
  attr_accessor :login

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :illustrations, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_illustrations, through: :likes, source: :illustration
  has_many :game_sessions, dependent: :destroy
  has_many :encyclopedia_entries, dependent: :destroy

  before_validation :normalize_profile_attributes

  validates :name, length: { maximum: 40 }, allow_blank: true
  validates :user_id,
            presence: true,
            length: { in: 3..40 },
            format: { with: /\A[a-zA-Z0-9_-]+\z/, message: :invalid_user_id_format },
            uniqueness: { case_sensitive: false }
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { in: 6..32 }, allow_blank: true

  def self.find_for_database_authentication(warden_conditions)
    login = warden_conditions[:login].to_s.strip.downcase
    return if login.blank?

    where("LOWER(email) = :login OR LOWER(user_id) = :login", login: login).first
  end

  private

  # 表示名・ログインに使う識別子の前後空白を保存前に統一する
  def normalize_profile_attributes
    self.name = name&.strip
    self.user_id = user_id&.strip
    self.email = email&.strip
  end
end
