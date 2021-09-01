class ChangeVersionDescriptionColumn < ActiveRecord::Migration[4.2]
  def up
    change_column :versions, :description, :text, { :default => nil }
  end

  def down
    change_column :versions, :description, :string, { :default => '' }
  end
end
