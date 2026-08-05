class CreateElements < ActiveRecord::Migration[8.1]
  def change
    create_table :elements do |t|
      t.integer :atomic_number, null: false
      t.string :symbol, null: false
      t.string :name, null: false
      t.string :english_name, null: false
      t.string :common_state, null: false
      t.text :description
      t.integer :period, null: false
      t.integer :group_number
      t.timestamps
    end
    add_index :elements, :atomic_number, unique: true
    add_index :elements, :symbol, unique: true
  end
end
