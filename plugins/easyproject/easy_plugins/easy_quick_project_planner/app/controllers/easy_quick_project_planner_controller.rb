class EasyQuickProjectPlannerController < ApplicationController

  include EasySettingHelper
  helper :issues
  helper :projects
  helper :custom_fields
  helper :easy_query

  before_action :require_admin, :only => [:plugin_settings]
  before_action :find_project, :authorize, :except => [:plugin_settings]
  before_action :load_quick_planner_field_setting, :except => [:plugin_settings]
  before_action :load_issues, :only => [:plan, :issues]

  def plan
    respond_to do |format|
      format.html {
        flash.now[:warning] = l(:warning_no_available_trackers) if @project.available_trackers.blank?
        if params[:for_dialog]
          render layout: false
        end
      }
    end
  end

  def new_issue_row
    if request.xhr?
      render partial: 'new_issue_row', :locals => {project: @project, issue: @issue, quick_planner_columns: @quick_planner_columns, editable_quick_planner_fields: @editable_quick_planner_fields}
    end
  end

  def load_created_issue
    @created_issue = Issue.visible.find(params[:issue_id])
    render :layout => false
  end

  def issues
    render partial: 'issues'
  end

  def save_setting
    save_easy_settings(@project)
  end

  def plugin_settings
    respond_to do |format|
      format.html
    end
  end

private

  def load_quick_planner_field_setting
    @issue = Issue.new
    @issue.project = @project
    @issue.safe_attributes = params[:issue]

    tracker_id = (params[:issue] && params[:issue][:tracker_id]) || params[:tracker_id]
    @issue.tracker_id = tracker_id.present? ? tracker_id.to_i : @project.available_trackers.first.try(:id)

    project_custom_fields = @project.all_issue_custom_fields.collect(&:id)
    @quick_planner_fields = EasySetting.value(:quick_planner_fields, @project).to_a.
      select{|field| field =~ (/cf_(\d+)/) ? project_custom_fields.include?($1.to_i) : true }

    available_cf = @issue.available_custom_fields.collect{|cf| "cf_#{cf.id}"} if @issue.safe_attribute_names.include?('custom_field_values')
    available_cf ||= []

    @editable_quick_planner_fields = @quick_planner_fields & (@issue.safe_attribute_names | available_cf)

    @query = EasyIssueQuery.new(:name => '_', :project => @project)
    @query.column_names = @quick_planner_fields.collect{|field| field.gsub(/_id$/, '')}

    @quick_planner_columns = @query.inline_columns.inject({}) do |result, column|
      result[column] = @quick_planner_fields.detect{|f| f.include?(column.name.to_s) }
      result
    end
  end

  def load_issues
    @issues = @query.entities(:order => "#{Issue.table_name}.updated_on DESC", :limit => 25)
    if calendar = EasyUserWorkingTimeCalendar.default
      @holidays = calendar.holidays.select([:holiday_date, :is_repeating])
    else
      @holidays = []
    end
  end

end
