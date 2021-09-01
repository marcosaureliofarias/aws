class MigrateAgileModules < ActiveRecord::Migration[4.2]
  def up
    EnabledModule.where(name: :easy_agile_board).update_all(name: :easy_scrum_board)
  end
  def down
    EnabledModule.where(name: :easy_scrum_board).update_all(name: :easy_agile_board)
  end
end
