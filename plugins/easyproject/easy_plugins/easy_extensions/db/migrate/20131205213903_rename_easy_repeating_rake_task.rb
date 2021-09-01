class RenameEasyRepeatingRakeTask < ActiveRecord::Migration[4.2]
  def up
    EasyRakeTask.where(:type => 'EasyRakeTaskRepeatingIssues').update_all(:type => 'EasyRakeTaskRepeatingEntities')
  end

  def down
  end
end
