class AddTimestampsToEasyPages < ActiveRecord::Migration[4.2]
  def up
    add_timestamps :easy_pages
    EasyPage.reset_column_information
    EasyPage.update_all(created_at: Time.now, updated_at: Time.now)
    change_column_null(:easy_pages, :created_at, false)
    change_column_null(:easy_pages, :updated_at, false)
  end

  def down
    remove_timestamps :easy_pages
  end
end
