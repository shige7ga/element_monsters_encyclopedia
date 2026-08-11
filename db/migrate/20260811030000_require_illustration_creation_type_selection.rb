class RequireIllustrationCreationTypeSelection < ActiveRecord::Migration[8.1]
  def change
    change_column_default :illustrations, :creation_type, from: "self_made", to: nil
    change_column_null :illustrations, :creation_type, true
  end
end
