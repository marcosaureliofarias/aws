class EasyTimesheetsController < ApplicationController

  menu_item :easy_timesheets

  before_action :authorize_global
  before_action :authorize_weekly, only: [:new, :create, :show]
  before_action :authorize_monthly, only: [:monthly_new, :monthly_create, :monthly_show, :monthly_resolve_lock]
  before_action :find_easy_timesheet, only: [:show, :edit, :update, :destroy, :resolve_lock, :copy]
  before_action :find_monthly_easy_timesheet, only: [:monthly_show, :monthly_resolve_lock]

  helper :easy_timesheets
  include EasyTimesheetsHelper
  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper
  helper :timelog
  include TimelogHelper

  def index
    index_for_easy_query EasyTimesheetQuery, [['start_date', 'desc']]
  end

  def show
    @previous = @easy_timesheet.previous
    @next = @easy_timesheet.next
    @easy_timesheet.copy_rows_from(EasyTimesheet.find(params[:copy_from_id])) if params[:copy_from_id].present?
    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    @easy_timesheet = EasyTimesheet.new(period: :week, start_date: User.current.today)
    @easy_timesheet.safe_attributes = params[:easy_timesheet]
    @easy_timesheet.user ||= User.current
    @start_date = @easy_timesheet.start_date

    @copy_from = EasyTimesheet.find(params[:copy_from_id]) if params[:copy_from_id].present?

    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @easy_timesheet = EasyTimesheet.new(:user => User.current)
    @easy_timesheet.safe_attributes = params[:easy_timesheet]
    @easy_timesheet.end_date ||= @easy_timesheet.calendar.enddt
    @copy_from = EasyTimesheet.find(params[:copy_from_id]) if params[:copy_from_id].present?
    if @easy_timesheet.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          if @copy_from
            @easy_timesheet.copy_rows_from(@copy_from)
            render(:show)
          else
            redirect_to(easy_timesheet_path(@easy_timesheet))
          end
        }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
      end
    end
  end

  def edit
    respond_to do |format|
      format.js
      format.html
    end
  end

  def update
    @easy_timesheet.safe_attributes = params[:easy_timesheet]
    if @easy_timesheet.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to easy_timesheet_path(@easy_timesheet)
        }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
      end
    end
  end

  def destroy
    @easy_timesheet.destroy if @easy_timesheet
    @easy_timesheets.destroy_all if @easy_timesheets

    respond_to do |format|
      flash[:notice] = l(:notice_successful_delete)
      format.html {redirect_to( easy_timesheets_path )}
      format.api { render_api_ok }
    end
  end

  def resolve_lock
    if params[:lock].nil? || params[:lock].to_s.to_boolean
      @locked = @easy_timesheet.lock!(params[:lock_description]) if @easy_timesheet.can_lock?
    else
      @locked = @easy_timesheet.unlock!(params[:lock_description]) if @easy_timesheet.can_unlock?
    end
    respond_to do |format|
      format.js
      format.html {redirect_to(@easy_timesheet)}
    end
  end

  def personal_show
    @calendar = EasyTimesheet.new.calendar(params[:start_date].presence)
    @easy_timesheet = EasyTimesheet.where(user_id: User.current.id).where('start_date >= ? AND end_date <= ?', @calendar.startdt, @calendar.enddt).first
    if @easy_timesheet.nil?
      @easy_timesheet = EasyTimesheet.new(user_id: User.current.id, start_date: @calendar.startdt, end_date: @calendar.enddt)
    else
      @previous = @easy_timesheet.previous
      @next = @easy_timesheet.next
    end

    respond_to do |format|
      format.html
    end
  end

  def monthly_new
    @easy_timesheet = EasyTimesheet.new(period: :month, start_date: User.current.today)
    @easy_timesheet.safe_attributes = params[:easy_timesheet]
    @easy_timesheet.user ||= User.current
    @start_date = @easy_timesheet.start_date

    @copy_from = EasyTimesheet.find(params[:copy_from_id]) if params[:copy_from_id].present?

    respond_to do |format|
      format.html
      format.js
    end
  end

  def monthly_create
    @easy_timesheet = EasyTimesheet.new(period: :month, user: User.current)
    @easy_timesheet.safe_attributes = params[:easy_timesheet]
    @easy_timesheet.end_date = @easy_timesheet.start_date.end_of_month
    @easy_timesheet.start_date = @easy_timesheet.start_date.beginning_of_month
    @day_range = @easy_timesheet.start_date..@easy_timesheet.end_date

    @copy_from = EasyTimesheet.find(params[:copy_from_id]) if params[:copy_from_id].present?
    if @easy_timesheet.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          if @copy_from
            @easy_timesheet.copy_rows_from(@copy_from)
            render(:monthly_show)
          else
            redirect_to(monthly_show_easy_timesheets_path(@easy_timesheet))
          end
        }
      end
    else
      respond_to do |format|
        format.html { render action: 'monthly_new' }
      end
    end
  end

  def monthly_show
    @easy_timesheet.copy_rows_from(EasyTimesheet.find(params[:copy_from_id])) if params[:copy_from_id].present?
    @day_range = @easy_timesheet.start_date..@easy_timesheet.end_date
    respond_to do |format|
      format.html
      format.js
    end
  end

  def monthly_resolve_lock
    if params[:lock].nil? || params[:lock].to_s.to_boolean
      @locked = @easy_timesheet.lock!(params[:lock_description]) if @easy_timesheet.can_lock?
    else
      @locked = @easy_timesheet.unlock!(params[:lock_description]) if @easy_timesheet.can_unlock?
    end
    respond_to do |format|
      format.js
      format.html { redirect_to(monthly_show_easy_timesheets_path(@easy_timesheet)) }
    end
  end

  private

  def find_easy_timesheet
    @easy_timesheet = EasyTimesheet.visible.find(params[:id]) if params[:id].present?
    @easy_timesheets = EasyTimesheet.visible.where(:id => params[:ids]) if params[:ids].present?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def timesheet_not_enabled(period = EasyTimesheet.default_period)
    period_name = l(period, scope: [:easy_timesheets_periods])
    render_error message: l(:notice_extended_timesheet_period_not_enabled, period: period_name), status: 403
  end

  def authorize_weekly
    timesheet_not_enabled('week') unless EasyTimesheet.weekly_calendar_enabled?
  end

  def find_monthly_easy_timesheet
    @easy_timesheet = EasyTimesheet.monthly.visible.find(params[:id]) if params[:id].present?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_monthly
    timesheet_not_enabled('month') unless EasyTimesheet.monthly_calendar_enabled?
  end

end
