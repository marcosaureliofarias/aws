class LongerUrlInEasyCustomMenus < ActiveRecord::Migration[4.2]
  def up
    change_column(:easy_custom_menus, :url, :string, limit: 2000)
  end

  def down

  end
end
