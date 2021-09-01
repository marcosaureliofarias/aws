class AddUniqIndexToEasyPageTabs < ActiveRecord::Migration[4.2]
  def up
    add_easy_uniq_index :easy_page_user_tabs, [:user_id, :page_id, :entity_id, :position], :name => 'idx_ep_user_tabs'
    add_easy_uniq_index :easy_page_template_tabs, [:page_template_id, :entity_id, :position], :name => 'idx_ep_template_tabs'
  end

  def down
  end
end