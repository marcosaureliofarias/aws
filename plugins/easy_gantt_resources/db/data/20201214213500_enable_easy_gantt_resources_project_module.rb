class EnableEasyGanttResourcesProjectModule < EasyExtensions::EasyDataMigration
  def up
    Project.has_module(:easy_gantt).where("not exists (select 1 FROM enabled_modules where projects.id = enabled_modules.project_id and enabled_modules.name = 'easy_gantt_resources')").find_each(batch_size: 100) do |project|
      project.enable_module!('easy_gantt_resources')
    end
  end

  def down
  end
end
