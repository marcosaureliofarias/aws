class MigrateEasyFavorites < EasyExtensions::EasyDataMigration
  def up
    EasyFavorite.transaction do
      if table_exists?(:favorite_issues)
        klass = Class.new(ActiveRecord::Base) { self.table_name = 'favorite_issues' }
        klass.all.each do |reference|
          EasyFavorite.create!(:entity_type => 'Issue', :entity_id => reference.issue_id, :user_id => reference.user_id)
        end
        drop_table :favorite_issues
      end

      if table_exists?(:favorite_projects)
        klass = Class.new(ActiveRecord::Base) { self.table_name = 'favorite_projects' }
        klass.all.each do |reference|
          EasyFavorite.create!(:entity_type => 'Project', :entity_id => reference.project_id, :user_id => reference.user_id)
        end
        drop_table :favorite_projects
      end

    end
  end

  def down
  end
end
