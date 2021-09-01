class EasyIcalendarsController < ApplicationController
  before_action :find_icalendar, only: [:sync]
  before_action :check_editable, only: [:sync]

  def sync
    ImportIcalEventsJob.perform_later(@ical) unless @ical.in_progress?
    head :ok
  end

  def get_item
    if params[:_new]
      @ical = User.current.easy_icalendars.build
    else
      @ical = User.current.easy_icalendars.find(params[:id])
    end
    respond_to do |format|
      format.js { render partial: 'external_calendars/get_item' }
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def create
    @ical = User.current.easy_icalendars.create(easy_icalendar_params)
    respond_to do |format|
      format.js { render partial: 'external_calendars/create' }
    end
  end

  private

  def find_icalendar
    @ical = EasyIcalendar.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def easy_icalendar_params
    params.require(:easy_icalendar).permit(:name, :url, :visibility)
  end

  def check_editable
    if User.current.easy_lesser_admin_for?(:users) || User.current == @ical.user
      true
    else
      render_403
    end
  end
end
