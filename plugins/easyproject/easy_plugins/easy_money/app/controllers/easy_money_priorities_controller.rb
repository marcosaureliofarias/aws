class EasyMoneyPrioritiesController < ApplicationController

  before_action :find_project_by_project_id, :only => [:update_priorities_to_subprojects]
  before_action :require_admin, :only => [:update_priorities_to_projects]
  before_action :my_authorize, :only => [:update_priorities_to_subprojects]

  helper :easy_money
  include EasyMoneyHelper

  def update_priorities_to_projects
    project_ids = Project.non_templates.has_module(:easy_money).pluck(:id)
    priorities = EasyMoneyRatePriority.where(:project_id => project_ids + [nil]).to_a.group_by{|p| p.project_id}
    default_priorities = priorities[nil] || []
    project_ids.each do |project_id|
      update_project_priorities(project_id, default_priorities, priorities)
    end

    if request.xhr?
      head :ok
    else
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default({:controller => 'easy_money_settings', :action => 'index', :tab => 'EasyMoneyRatePriority'})
    end
  end

  def update_priorities_to_subprojects
    project_ids = @project.self_and_descendants.active.has_module(:easy_money).pluck(:id)
    priorities = EasyMoneyRatePriority.where(:project_id => project_ids).to_a.group_by{|p| p.project_id}
    default_priorities = priorities[@project.id] || []
    project_ids.each do |project_id|
      update_project_priorities(project_id, default_priorities, priorities) if project_id != @project.id
    end

    if request.xhr?
      head :ok
    else
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default({:controller => 'easy_money_settings', :action => 'project_settings', :project_id => @project, :tab => 'EasyMoneyRatePriority'})
    end
  end

  private

  def my_authorize
    unless @project.nil?
      authorize
    end
  end

  def find_project_by_project_id
    @project = Project.find(params[:project_id]) if params[:project_id]
  end

  def update_project_priorities(project_id, default_priorities, priorities)
    project_priorities = priorities[project_id]
    default_priorities.each do |default_priority|
      if project_priorities
        project_priority = project_priorities.detect{|p| p.rate_type_id == default_priority.rate_type_id && p.entity_type == default_priority.entity_type }
        if project_priority
          update_priority(project_priority, default_priority)
        else
          create_priority(project_id, default_priority)
        end
      else
        create_priority(project_id, default_priority)
      end

    end
  end

  def create_priority(project_id, default_priority)
    EasyMoneyRatePriority.create(:project_id => project_id, :rate_type_id => default_priority.rate_type_id, :entity_type => default_priority.entity_type, :position => default_priority.position)
  end

  def update_priority(project_priority, default_priority)
    project_priority.position = default_priority.position
    project_priority.save
  end

end
