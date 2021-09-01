class ProjectDestroyJob < EasyActiveJob

  def perform(project_id)
    project = Project.find_by(id: project_id)
    return unless project&.scheduled_for_destroy?

    project.children.each do |child|
      Project.delete_easy_page_modules child.id
    end
    Project.delete_easy_page_modules project.id
    
    project.destroy
  end

end