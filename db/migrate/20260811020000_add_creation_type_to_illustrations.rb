class AddCreationTypeToIllustrations < ActiveRecord::Migration[8.1]
  def change
    add_column :illustrations, :creation_type, :string, null: false, default: "self_made"
  end
end
