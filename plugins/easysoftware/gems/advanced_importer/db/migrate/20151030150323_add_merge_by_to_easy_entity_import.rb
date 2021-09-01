class AddMergeByToEasyEntityImport < ActiveRecord::Migration[5.2]
  def change
    unless column_exists? :easy_entity_imports, :merge_by
      add_column :easy_entity_imports, :merge_by, :string, :default => 'easy_external_id'
    end
  end
end
