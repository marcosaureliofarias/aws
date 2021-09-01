class IncreaseSizeOfJournalizedType < ActiveRecord::Migration[4.2]
  def up
    change_column :journals, :journalized_type, :string, :limit => 60
  end

  def down
    change_column :journals, :journalized_type, :string, :limit => 30
  end
end
