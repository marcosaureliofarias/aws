class AddEasyExternalIdToNews < ActiveRecord::Migration[4.2]
  def up
    unless column_exists?(:news, :easy_external_id)
      add_column :news, :easy_external_id, :integer
    end
  end

  def down
    if column_exists?(:news, :easy_external_id)
      remove_column :news, :easy_external_id
    end
  end
end
