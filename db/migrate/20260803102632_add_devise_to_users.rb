# frozen_string_literal: true

class AddDeviseToUsers < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :user_id, false
    add_index :users, :user_id, unique: true
  end
end
