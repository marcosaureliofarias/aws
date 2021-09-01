class ProjectMassCopyController < ApplicationController

  before_action :render_403, if: -> { !EasyLicenseManager.has_license_limit?(:active_project_limit) }
  before_action :find_source_project, :only => [:select_target_projects, :select_actions, :copy]
  before_action :find_target_projects, :only => [:select_actions, :copy]

  def select_source_project
    @projects          = Project.visible.non_templates.sorted
    @project_templates = Project.visible.templates.sorted
  end

  def select_target_projects
    @projects          = Project.visible.non_templates.sorted
    @project_templates = Project.visible.templates.sorted
  end

  def select_actions
  end

  def copy
    only = params[:only]

    if only && only.is_a?(Array)
      errs = []
      only.each do |action_name|
        next if action_name.blank?
        method_name = "copy_#{action_name}".to_sym
        ret_val     = send(method_name)
        errs << ret_val if ret_val != true
      end

      if errs.blank?
        flash[:notice] = l(:notice_successful_update)
      else
        flash[:error] = errs.join('<br>').html_safe
      end
    end

    redirect_back_or_default({ :controller => 'admin', :action => 'projects' })
  end

  private

  def copy_activity
    @target_projects.each do |target_project|
      target_project.send(:delete_time_entry_activities)
      ProjectActivityRole.where(:project_id => target_project.id).delete_all

      target_project.send(:copy_activity, @source_project)
    end

    true
  end

  def copy_project_overview
    @target_projects.each do |target_project|
      EasyPageZoneModule.delete_modules(EasyPage.find_by(page_name: 'project-overview'), nil, target_project.id)
      EasyPageZoneModule.clone_by_entity_id(@source_project.id, target_project.id)
    end

    true
  end

  def copy_members
    @target_projects.each do |target_project|
      target_project.delete_all_members
      target_project.send(:copy_members, @source_project)
    end

    true
  end

  def find_source_project
    @source_project = Project.find(params[:source_project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_target_projects
    @target_projects = Project.find(params[:target_projects])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
