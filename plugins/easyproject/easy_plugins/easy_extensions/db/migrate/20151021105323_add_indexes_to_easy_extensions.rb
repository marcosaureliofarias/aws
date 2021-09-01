class AddIndexesToEasyExtensions < ActiveRecord::Migration[4.2]
  def up
    add_easy_uniq_index :easy_page_available_modules, [:easy_pages_id, :easy_page_modules_id], :name => 'idx_av_modules'
    add_easy_uniq_index :easy_page_available_zones, [:easy_pages_id, :easy_page_zones_id], :name => 'idx_av_zones'

    add_index :easy_queries, :user_id, :name => 'idx_easy_queries_user_id' unless index_exists?(:easy_queries, :user_id, :name => 'idx_easy_queries_user_id')
    add_index :easy_queries, :project_id, :name => 'idx_easy_queries_project_id' unless index_exists?(:easy_queries, :project_id, :name => 'idx_easy_queries_project_id')
  end

  def down
  end
end