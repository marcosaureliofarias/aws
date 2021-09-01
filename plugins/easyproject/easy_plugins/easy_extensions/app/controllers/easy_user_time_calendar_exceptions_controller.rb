class EasyUserTimeCalendarExceptionsController < ApplicationController

  before_action { |c| c.require_admin_or_lesser_admin(:working_time) }
  before_action :find_exception, only: [:show, :update, :destroy]
  before_action :find_calendar, only: [:exceptions_from_calendar]

  accept_api_auth :index, :show, :create, :update, :destroy, :exceptions_from_calendar

  helper :api_easy_user_time_calendar_exceptions

  def index
    @easy_user_time_calendar_exceptions = EasyUserTimeCalendarException.all

    respond_to do |format|
      format.api
    end
  end

  def exceptions_from_calendar
    @easy_user_time_calendar_exceptions = EasyUserTimeCalendarException.where(calendar_id: @user_time_calendar.id)

    respond_to do |format|
      format.api
    end
  end

  def show
    respond_to do |format|
      format.api
    end
  end

  def create
    @easy_user_time_calendar_exception                 = EasyUserTimeCalendarException.new
    @easy_user_time_calendar_exception.safe_attributes = params[:easy_user_time_calendar_exception]

    if @easy_user_time_calendar_exception.save
      respond_to do |format|
        format.api { render action: 'show', status: :created }
      end
    else
      respond_to do |format|
        format.api { render_validation_errors(@easy_user_time_calendar_exception) }
      end
    end
  end

  def update
    @easy_user_time_calendar_exception.safe_attributes = params[:easy_user_time_calendar_exception]
    if @easy_user_time_calendar_exception.save
      respond_to do |format|
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.api { render_validation_errors(@easy_user_time_calendar_exception) }
      end
    end
  end

  def destroy
    @easy_user_time_calendar_exception.destroy

    respond_to do |format|
      format.api { render_api_ok }
    end
  end

  private

  def find_exception
    @easy_user_time_calendar_exception = EasyUserTimeCalendarException.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_calendar
    @user_time_calendar = EasyUserTimeCalendar.find(params[:calendar_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
