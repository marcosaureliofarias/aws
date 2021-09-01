class AddShowAvatarsToEasyQuery < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_queries, :show_avatars, :boolean, { default: true }
  end
end
