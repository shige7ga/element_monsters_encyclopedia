class CreateLearningSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :learning_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :score, null: false
      t.integer :total_questions, null: false

      t.timestamps
    end
  end
end
