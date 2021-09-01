class EasyUserWorkingTimeCalendarsController < ApplicationController
  layout 'admin'
  menu_item(:working_time)

  before_action { |c| c.require_admin_or_lesser_admin(:working_time) }
  before_action :find_calendar, :except => [:index, :new, :create, :assign_to_user]
  before_action :prepare_variables, :only => [:show, :inline_show, :inline_edit, :inline_update]
  before_action :find_user, :only => [:assign_to_user]

  accept_api_auth :index, :show, :create, :update, :destroy, :assign_to_user

  helper :api_easy_user_working_time_calendars

  def index
    @easy_user_working_time_calendars = EasyUserWorkingTimeCalendar.templates

    respond_to do |format|
      format.html
      format.api
    end
  end

  def show
    respond_to do |format|
      format.html
      format.api
    end
  end

  def new
    @easy_user_working_time_calendar = EasyUserWorkingTimeCalendar.new

    if params[:inherit]
      parent                                                 = EasyUserWorkingTimeCalendar.find(params[:inherit])
      @easy_user_working_time_calendar.parent_id             = parent.id
      @easy_user_working_time_calendar.default_working_hours = parent.default_working_hours
      @easy_user_working_time_calendar.first_day_of_week     = parent.first_day_of_week
    end

    respond_to do |format|
      format.html
    end
  end

  def create
    @easy_user_working_time_calendar                 = EasyUserWorkingTimeCalendar.new
    @easy_user_working_time_calendar.safe_attributes = params[:easy_user_working_time_calendar]
    @easy_user_working_time_calendar.ical_update     = true

    if @easy_user_working_time_calendar.save

      unless params[:inherit].blank?
        inherit_from = EasyUserWorkingTimeCalendar.find(params[:inherit])

        if inherit_from && params[:copy_exceptions] == '1'
          @easy_user_working_time_calendar.exceptions << inherit_from.exceptions.collect { |e| e.dup }
        end

        if inherit_from && params[:copy_holidays] == '1'
          ical_uids = @easy_user_working_time_calendar.holidays.pluck(:ical_uid)
          @easy_user_working_time_calendar.holidays << inherit_from.holidays.reject { |h| ical_uids.include?(h.ical_uid) }.collect { |h| h.dup }
        end
      end

      respond_to do |format|
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_to :action => 'index' }
        format.api { render action: 'show', status: :created }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api { render_validation_errors(@easy_user_working_time_calendar) }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    @easy_user_working_time_calendar.transaction do
      @easy_user_working_time_calendar.holidays.destroy_all if params[:ical_overwrite] == '1'
      @easy_user_working_time_calendar.reload

      @easy_user_working_time_calendar.ical_update     = true if params[:ical_update] == '1'
      @easy_user_working_time_calendar.safe_attributes = params[:easy_user_working_time_calendar]
      if @easy_user_working_time_calendar.save
        flash[:notice] = l(:notice_successful_update)
        respond_to do |format|
          format.html { redirect_to params[:back_url] || { :action => 'index' } }
          format.api { render_api_ok }
        end
      else
        respond_to do |format|
          format.html do
            if params[:back_url].blank?
              render :action => 'edit'
            else
              flash[:error] = @easy_user_working_time_calendar.errors.full_messages.join('<br>').html_safe
              redirect_back_or_default(:action => 'edit', :id => @easy_user_working_time_calendar)
            end
          end
          format.api { render_validation_errors(@easy_user_working_time_calendar) }
        end
      end
    end
  end

  def destroy
    @easy_user_working_time_calendar.destroy unless @easy_user_working_time_calendar.builtin?
    flash[:notice] = l(:notice_successful_delete)

    respond_to do |format|
      format.html { redirect_to :action => 'index' }
      format.api { render_api_ok }
    end
  end

  def inline_show
    respond_to do |format|
      format.js
    end
  end

  def inline_edit
    respond_to do |format|
      format.js
    end
  end

  def inline_update
    if (@working_hours == 0.0 && (@easy_user_working_time_calendar.weekend?(@day) || @easy_user_working_time_calendar.holiday?(@day))) ||
        (@working_hours == @easy_user_working_time_calendar.default_working_hours && (!@easy_user_working_time_calendar.weekend?(@day) && !@easy_user_working_time_calendar.holiday?(@day)))
      exc = EasyUserTimeCalendarException.where(["#{EasyUserTimeCalendarException.table_name}.calendar_id = ? AND #{EasyUserTimeCalendarException.table_name}.exception_date = ?", @easy_user_working_time_calendar.id, @day]).first
      exc.destroy if exc
    else
      exc               = EasyUserTimeCalendarException.where(["#{EasyUserTimeCalendarException.table_name}.calendar_id = ? AND #{EasyUserTimeCalendarException.table_name}.exception_date = ?", @easy_user_working_time_calendar.id, @day]).first
      exc               ||= EasyUserTimeCalendarException.new(:calendar_id => @easy_user_working_time_calendar.id, :exception_date => @day)
      exc.working_hours = @working_hours
      exc.save
    end

    find_calendar && prepare_variables #reload

    render :action => 'inline_show'
  end

  def assign_to_user
    parent_calendar              = EasyUserWorkingTimeCalendar.find(params[:working_time_calendar]) if params[:working_time_calendar].present?
    current_calendar             = EasyUserWorkingTimeCalendar.find_by_user(@user)
    preserve_calendar_exceptions = params[:preserve_calendar_exceptions] == '1'

    if parent_calendar && parent_calendar != current_calendar
      parent_calendar.assign_to_user(@user, preserve_calendar_exceptions)
      flash[:notice] = l(:notice_successful_create)
    elsif !parent_calendar && current_calendar
      current_calendar.destroy
      flash[:notice] = l(:notice_successful_delete)
    end

    respond_to do |format|
      format.html { redirect_to params[:back_url] }
      format.api { render_api_ok }
    end
  end

  def reset
    @easy_user_working_time_calendar.reset

    flash[:notice] = l(:notice_successful_update)
    redirect_to params[:back_url]
  end

  def mass_exceptions
    mass_exception = params[:mass_exception]
    if mass_exception
      from          = begin
        ; mass_exception[:from].to_date;
      rescue;
      end
      to            = begin
        ; mass_exception[:to].to_date;
      rescue;
      end
      working_hours = mass_exception[:working_hours].to_f
      day_period    = mass_exception[:day_period].to_i

      if from && to
        (from..to).each do |day|
          if (day.cwday == day_period && !mass_exception[:overwrite].nil?) ||
              (day.cwday == day_period && !@easy_user_working_time_calendar.holiday?(day) && !@easy_user_working_time_calendar.exception?(day))
            exc               = EasyUserTimeCalendarException.where(:calendar_id => @easy_user_working_time_calendar.id, :exception_date => day).first
            exc               ||= EasyUserTimeCalendarException.new(:calendar_id => @easy_user_working_time_calendar.id, :exception_date => day)
            exc.working_hours = working_hours
            exc.save
          end
        end
        flash[:notice] = l(:notice_successful_update)
      end
      url = mass_exception[:back_url].presence
    end

    redirect_to url || @easy_user_working_time_calendar
  end

  private

  def find_calendar
    @easy_user_working_time_calendar = EasyUserWorkingTimeCalendar.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def prepare_variables
    unless params[:day].blank?
      @day = begin
        ; params[:day].to_date;
      rescue;
      end
    end
    @working_hours = params[:working_hours].to_f if params[:working_hours]
    unless params[:start_date].blank?
      @start_date = begin
        ; params[:start_date].to_date;
      rescue;
      end
    end
    @start_date ||= Date.today
    @easy_user_working_time_calendar.initialize_inner_calendar(@start_date)
  end

  def find_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
