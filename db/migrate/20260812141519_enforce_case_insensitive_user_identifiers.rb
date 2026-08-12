class EnforceCaseInsensitiveUserIdentifiers < ActiveRecord::Migration[8.1]
  def up
    normalize_existing_identifiers!
    ensure_identifiers_are_present!
    ensure_case_insensitive_identifiers_are_unique!

    change_column_null :users, :user_id, false
    change_column_null :users, :email, false
    remove_index :users, :user_id
    remove_index :users, :email
    add_index :users, "LOWER(user_id)", unique: true, name: "index_users_on_lower_user_id"
    add_index :users, "LOWER(email)", unique: true, name: "index_users_on_lower_email"
  end

  def down
    remove_index :users, name: "index_users_on_lower_user_id"
    remove_index :users, name: "index_users_on_lower_email"
    add_index :users, :user_id, unique: true
    add_index :users, :email, unique: true
  end

  private

  # 既存データも新規入力と同じ前後空白除去ルールに揃える
  def normalize_existing_identifiers!
    execute <<~SQL.squish
      UPDATE users
      SET user_id = BTRIM(user_id), email = BTRIM(email), name = BTRIM(name)
    SQL
  end

  # 制約追加前に不正な既存データを検出し、暗黙のデータ変更を避ける
  def ensure_identifiers_are_present!
    invalid_identifiers = select_value(<<~SQL.squish).to_i
      SELECT COUNT(*)
      FROM users
      WHERE user_id IS NULL OR BTRIM(user_id) = '' OR email IS NULL OR BTRIM(email) = ''
    SQL
    return if invalid_identifiers.zero?

    raise ActiveRecord::MigrationError, "usersに空のuser_idまたはemailが存在するため、制約を追加できません。"
  end

  # 大文字小文字を無視した重複がある場合は、対象を明示して移行を停止する
  def ensure_case_insensitive_identifiers_are_unique!
    duplicate_user_id = select_value("SELECT LOWER(user_id) FROM users GROUP BY LOWER(user_id) HAVING COUNT(*) > 1 LIMIT 1")
    duplicate_email = select_value("SELECT LOWER(email) FROM users GROUP BY LOWER(email) HAVING COUNT(*) > 1 LIMIT 1")
    return unless duplicate_user_id || duplicate_email

    duplicates = []
    duplicates << "user_id: #{duplicate_user_id}" if duplicate_user_id
    duplicates << "email: #{duplicate_email}" if duplicate_email
    raise ActiveRecord::MigrationError, "大文字小文字を無視した重複が存在するため、制約を追加できません（#{duplicates.join(', ')}）。"
  end
end
