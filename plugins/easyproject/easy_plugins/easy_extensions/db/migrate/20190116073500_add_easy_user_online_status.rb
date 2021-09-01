class AddEasyUserOnlineStatus < ActiveRecord::Migration[5.2]

  def change

    add_column :users, :easy_online_status, :integer, { null: false, default: 0, index: true }
    add_column :users, :easy_online_status_changed_at, :datetime, { null: true }

  end

end
