namespace :easy_gantt_resources do

  desc 'Reallocating all issues'
  task :reallocate_resources => :environment do
    EasyGanttResources::IssueAllocator.reallocate!
  end

  desc 'Clear default allocators for all projects'
  task clear_default_allocators: :environment do
    EasySetting.where(name: 'easy_gantt_resources_default_allocator').where.not(project_id: nil).destroy_all
  end

end
