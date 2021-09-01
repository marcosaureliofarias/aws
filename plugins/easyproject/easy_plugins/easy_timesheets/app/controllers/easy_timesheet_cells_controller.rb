class EasyTimesheetCellsController < ApplicationController

  helper :easy_timesheets

  before_action :find_easy_timesheet
  before_action :find_time_entry, only: [:update, :destroy]
  before_action :authorize_easy_timesheet
  before_action :find_row, only: [:create, :update, :destroy]

  def create
    over_time = params[:easy_timesheet_row] && params[:easy_timesheet_row][:over_time] == 'true' ? '1' : '0'
    time_entry_params = params[:time_entry] || {}
    time_entry_params[:custom_field_values] ||= {}
    time_entry_params[:custom_field_values].merge(EasySetting.value(:easy_timesheets_custom_field_overtime_id).to_s => over_time)

    call_hook(:controller_easy_timesheet_cells_create_top, params: params)

    spent_on = begin time_entry_params[:spent_on].to_date; rescue nil; end
    render_404 if spent_on.nil?

    @row ||= @easy_timesheet.build_new_row
    @row.attributes = params[:easy_timesheet_row] if @row.is_new_row?

    @time_entry = TimeEntry.new
    @time_entry.user_id = @easy_timesheet.user_id
    @time_entry.project_id = @row.project_id
    @time_entry.issue_id = @row.issue_id
    @time_entry.activity_id = @row.activity_id
    @time_entry.spent_on = spent_on
    @time_entry.safe_attributes = time_entry_params
    @time_entry.comments ||= '-' if EasyGlobalTimeEntrySetting.value('required_time_entry_comments', User.current.roles_for_project(@row.project))

    @was_new_row = @row.is_new_row?

    if @row.is_new_row? && (existing_row = @easy_timesheet.find_row(@row.dom_id))
      @row = existing_row
    end

    @easy_timesheet.time_entries << @time_entry
    if @time_entry.save
      # add new time_entry to row
      @row.add_time_entry(@time_entry)
      @row.is_new_row = false
    end
    respond_to_create_new_time_entry
  end

  def update
    return render_404 if @row.nil? || @time_entry.nil?
    @time_entry.safe_attributes = params[:time_entry]
    @spent_on = @time_entry.spent_on.to_s
    if @time_entry.save
      # update row with changed time_entry
      @row.add_time_entry(@time_entry)
      @tfoot_hours = @easy_timesheet.sum_row(true).each_cell.detect{|i| i.spent_on == @spent_on}.try(:sum_hours) || 0
    else
      render js: "alert('#{@time_entry.errors.full_messages.join('\n').html_safe}');"
    end
  end

  def show
    @row = @easy_timesheet.find_row(params[:row_id])
    return render_404 if @row.nil?

    @cell = @row.cells.detect{|cell| cell.spent_on == params[:cell_id]}
    render_404 if @cell.nil?

    @time_entries = @cell.time_entries

    respond_to do |format|
      format.js
    end
  end

  def destroy
    return render_404 if @row.nil? || @time_entry.nil?

    @spent_on = @time_entry.spent_on.to_s
    if @time_entry.destroy
      # remove time_entry from row
      @row.add_time_entry(@time_entry)
      @tfoot_hours = @easy_timesheet.sum_row(true).each_cell.detect{|i| i.spent_on == @spent_on}.try(:sum_hours) || 0
    else
      render js: "alert('#{@time_entry.errors.full_messages.join('\n').html_safe}');"
    end
  end

  private

  def find_easy_timesheet
    @easy_timesheet = EasyTimesheet.find(params[:id])

  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_easy_timesheet
    @easy_timesheet.addable? ? true : render_403
  end

  def find_time_entry
    @time_entry = TimeEntry.find(params[:time_entry_id])
    unless @time_entry.editable_by?(User.current)
      render_403
      return false
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_row
    @row = @easy_timesheet.find_row(params[:row_id])
  end

  def respond_to_create_new_time_entry
    respond_to do |format|
      format.js
    end
  end

end
