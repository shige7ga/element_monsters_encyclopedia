# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

load Rails.root.join("db/seeds/elements.rb")

# 管理者: credentialsの認証情報を参照し、既存の管理者は変更しない。
require "digest"

admin_email = Rails.application.credentials.dig(:admin, :email)
admin_password = Rails.application.credentials.dig(:admin, :password)

if admin_email.blank? || admin_password.blank?
  raise "管理者のcredentialsが設定されていません。"
end

existing_admin_user = User.find_by(email: admin_email)
admin_user_id = "admin_#{Digest::SHA256.hexdigest(admin_email).first(12)}"

if existing_admin_user.nil?
  User.create!(
    email: admin_email,
    password: admin_password,
    password_confirmation: admin_password,
    user_id: admin_user_id,
    name: "管理者",
    admin: true
  )
elsif !existing_admin_user.admin?
  raise "同一メールアドレスの一般ユーザーが存在するため、管理者を作成できません。"
end
