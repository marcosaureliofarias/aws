class CreateEasyPagePermissions < RedmineExtensions::Migration

  def up
    create_table :easy_page_permissions do |t|
      t.references :easy_page
      t.references :entity, polymorphic: true, index: true
    end
  end

  def down
    drop_table :easy_page_permissions
  end

end
