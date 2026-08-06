class CreateIllustrations < ActiveRecord::Migration[8.1]
  def change
    create_table :illustrations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :element, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.text :memory_tip
      t.boolean :published, null: false, default: true

      t.timestamps
    end

    add_index :illustrations, :published
  end
end
