class EasyRakeTaskIssueAllocationsRecalculation < EasyRakeTask

  def execute
    EasyGanttResources::IssueAllocator.reallocate!
  end

  def category_caption_key
    :project_module_easy_gantt
  end

  def registered_in_plugin
    :easy_gantt_resources
  end

end
