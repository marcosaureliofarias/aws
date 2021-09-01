class MigrateAgilePermissions < ActiveRecord::Migration[4.2]
  def up
    Role.transaction do
      Role.all.each do |role|
        if role.has_permission?(:view_easy_agile_board)
          role.add_permission! :view_easy_scrum_board
          role.remove_permission! :view_easy_agile_board
        elsif role.has_permission?(:edit_easy_agile_board)
          role.add_permission! :edit_easy_scrum_board
          role.remove_permission! :edit_easy_agile_board
        end
      end
    end
  end

  def down
    Role.all.each do |role|
      if role.has_permission?(:view_easy_scrum_board)
        role.add_permission! :view_easy_agile_board
        role.remove_permission! :view_easy_scrum_board
      elsif role.has_permission?(:edit_easy_scrum_board)
        role.add_permission! :edit_easy_agile_board
        role.remove_permission! :edit_easy_scrum_board
      end
    end
  end
end
