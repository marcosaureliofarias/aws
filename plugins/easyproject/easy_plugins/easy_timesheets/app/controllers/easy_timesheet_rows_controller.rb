class EasyTimesheetRowsController < ApplicationController

  helper :easy_timesheets
  include TimelogHelper

  before_action :find_easy_timesheet
  before_action :authorize_easy_timesheet
  before_action :find_easy_timesheet_row, only: [:delete, :destroy]

  def new
    @row = @easy_timesheet.build_new_row

    respond_to do |format|
      format.js
    end
  end

  def delete
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @row.destroy(!!params[:destroy_time_entries])
    if !!params[:destroy_time_entries] && @row.time_entries.reject(&:destroyed?).any?
      flash[:error] = l(:validation_timesheet_cant_destroy_time_entries)
    else
      @easy_timesheet.remove_row(@row)
    end

    respond_to do |format|
      format.js
    end
  end

  def valid
    @over_time = params[:over_time].to_boolean
    @row = @easy_timesheet.build_new_row

    @project = Project.find(params[:project_id]) if params[:project_id].present?
    @issue = @project.issues.where(id: params[:issue_id]).first if @project && params[:issue_id].present?

    if @project
      if @project.fixed_activity?
        if @issue
          @activity = @issue.activity
        else
          get_activities
        end
      else
        get_activities
        @activity = @project.project_time_entry_activities.where(:id => params[:activity_id]).first if params[:activity_id].present?
      end
    end


    if @project && @activity
      @new_row = @easy_timesheet.build_new_row

      @time_entry = TimeEntry.new
      @time_entry.user_id = @easy_timesheet.user_id
      @time_entry.project_id = @project.id
      @time_entry.activity_id = @activity.id
      @time_entry.issue_id = @issue.id if @issue

      @new_row.add_time_entry(@time_entry)
    end

    respond_to_valid_new_row
  end

  private

  def get_activities
    @activities_collection = activity_collection(@easy_timesheet.user, 'xAll', @project)
  end

  def find_easy_timesheet
    @easy_timesheet = EasyTimesheet.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_easy_timesheet_row
    @row = @easy_timesheet.find_row(params[:row_id])
    render_404 unless @row
  end

  def authorize_easy_timesheet
    @easy_timesheet.addable? ? true : render_403
  end

  def respond_to_valid_new_row
    respond_to do |format|
      format.js
    end
  end
end
