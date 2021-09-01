class EasyCustomMenusSetDefaultPosition < EasyExtensions::EasyDataMigration
  def up
    EasyUserType.find_each(batch_size: 200) do |user_type|
      user_type.easy_custom_menus.where(root_id: nil).order(Arel.sql("COALESCE(#{EasyCustomMenu.table_name}.root_id, #{EasyCustomMenu.table_name}.id), #{EasyCustomMenu.table_name}.root_id, #{EasyCustomMenu.table_name}.id")).each_with_index do |menu, i|
        menu.update_column(:position, i + 1)
        menu.submenus.each_with_index do |submenu, id|
          submenu.update_column(:position, id + 1)
        end
      end
    end
  end

  def down
    EasyCustomMenu.update_all(position: nil)
  end
end
