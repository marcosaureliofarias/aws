class ChangeOrAddIndexes < ActiveRecord::Migration[4.2]
  def self.up
    remove_index :easy_page_zone_modules, :name => 'idx_easy_page_zone_modules_1'
    add_index :easy_page_zone_modules, [:easy_pages_id, :easy_page_available_zones_id, :user_id, :entity_id], :name => 'idx_easy_page_zone_modules_1'

    add_index :easy_page_template_modules, [:easy_page_templates_id, :easy_page_available_zones_id, :entity_id], :name => 'idx_easy_page_template_modules_3'

    add_index :easy_queries, [:id, :type], :name => 'idx_easy_queries_1'

    add_index :projects, [:lft, :rgt], :name => 'idx_projects_tree_1'
    add_index :projects, [:lft], :name => 'idx_projects_tree_2'

    add_index :issues, [:lft], :name => 'idx_issues_tree_1'
  end

  def self.down
    remove_index :easy_queries, :name => 'idx_easy_queries_1'

    remove_index :projects, :name => 'idx_projects_tree_1'
    remove_index :projects, :name => 'idx_projects_tree_2'

    remove_index :issues, :name => 'idx_issues_tree_1'
  end
end
