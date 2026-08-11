class CreateEncyclopediaEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :encyclopedia_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :element, null: false, foreign_key: true
      t.references :illustration, null: false, foreign_key: true

      t.timestamps
    end

    add_index :encyclopedia_entries, %i[user_id element_id], unique: true
  end
end
