class RenameIllustrationTitleAndRemoveMemoryTip < ActiveRecord::Migration[8.1]
  def change
    rename_column :illustrations, :title, :monster_name
    remove_column :illustrations, :memory_tip, :text
  end
end
