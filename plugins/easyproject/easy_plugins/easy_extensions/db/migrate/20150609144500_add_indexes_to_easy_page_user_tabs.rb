class AddIndexesToEasyPageUserTabs < ActiveRecord::Migration[4.2]
  def change
    add_index :easy_page_user_tabs, :entity_id, :name => 'idx_eput_entity_id'
    add_index :easy_page_user_tabs, :page_id, :name => 'idx_eput_page_id'
    add_index :easy_page_user_tabs, :user_id, :name => 'idx_eput_user_id'
    add_index :easy_page_user_tabs, :position, :name => 'idx_eput_position'
  end
end
