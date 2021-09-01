class EasyCalendarController < ApplicationController
  accept_rss_auth :user_availability
  accept_api_auth :user_availability, :feed

  before_action :authorize_global, only: [:feed, :index]
  before_action :parse_date_limits, except: [:save_availability, :index, :edit_page_layout]
  before_action :find_user, only: [:user_availability], if: -> { params.has_key?(:user_id) }

  EasyExtensions::EasyPageHandler.register_for(self, {
    page_name: 'easy-calendar-module',
    path: proc { easy_calendar_path(t: params[:t]) },
    show_action: :index,
    edit_action: :edit_page_layout
  })

  def feed
    settings = if params[:module_id].present? && (@module = EasyPageZoneModule.find_by(uuid: params[:module_id]))
                 @module.settings
               elsif params[:enabled_calendars].present?
                 { enabled_calendars: params[:enabled_calendars] }
               elsif User.current.logged? && User.current.pref[:easy_calendar]
                 User.current.pref[:easy_calendar]
               else
                 { enabled_calendars: ['easy_meeting_calendar'] }
               end

    settings[:controller] = self
    @events = if @start_date && @end_date
                EasyCalendar::AdvancedCalendar.events(@start_date, @end_date, settings)
              else
                []
              end
    respond_to do |format|
      format.json do
        render json: @events.collect { |e| Hash[e.map { |k, v| [k.to_s.camelcase(:lower), v] }] }
      end
    end
  end

  def project_meetings
    @module = EasyPageZoneModule.find(params[:module_id])

    @project = Project.find(params[:project_id])

    if @start_date && @end_date
      @events = EasyCalendar::AdvancedCalendar.project_events(@start_date, @end_date, @project, @module.settings.merge({controller: self}))
    else
      @events = []
    end

    respond_to do |format|
      format.json { render :json => @events.collect { |e| Hash[e.map { |k, v| [k.to_s.camelcase(:lower), v] }] } }
    end
  end

  def room_meetings
    @room = EasyRoom.find(params[:room_id])

    if @start_date && @end_date
      @events = EasyCalendar::AdvancedCalendar.room_events(@start_date, @end_date, @room, {controller: self})
    else
      @events = []
    end

    respond_to do |format|
      format.json { render :json => @events.collect { |e| Hash[e.map { |k, v| [k.to_s.camelcase(:lower), v] }] } }
    end
  end

  def get_ics
    @user = User.find(params[:user_id]) if params[:user_id].present?
    @user = nil if @user == User.current
    @link = easy_calendar_ics_url({:user_id => @user, :key => User.current.api_key, :format => 'ics'})
    @easy_qr = EasyQr.generate_qr(@link)
    respond_to do |format|
      format.js
      format.html
    end
  end

  def user_availability
    @user ||= User.current
    @events = []

    collect_meeting_events!
    collect_attendance_events! if Redmine::Plugin.installed?(:easy_attendances) && User.current.allowed_to_globally?(:view_easy_attendances)
    params[:with_easy_entity_activities] = true

    call_hook(:controller_easy_calendar_action_user_availability_before_map_events,
              events: @events,
              user: @user,
              start_date: @start_date,
              end_date: @end_date,
              calendar_type: params[:calendar_type])

    respond_to do |format|
      format.json do
        @events.map! { |event| EasyCalendarEvent.create(event) }
        render json: @events
      end
      format.ics do
        icalendar = Icalendar::Calendar.new
        @events.each { |evt| icalendar.add_event(EasyCalendarEvent.create(evt).to_ical) }
        render plain: icalendar.to_ical
      end
    end
  end

  def save_availability
    if (@module = EasyPageZoneModule.find_by(uuid: params[:module_id]))
      @module.settings ||= {}
      @module.settings[:user_ids] = params[:user_ids] ? params[:user_ids].collect(&:to_i) : []
      @module.save
    elsif User.current.logged?
      settings = User.current.pref[:easy_calendar]
      settings ||= {}
      settings[:user_ids] = params[:user_ids] ? params[:user_ids].collect(&:to_i) : []
      User.current.pref[:easy_calendar] = settings
      User.current.pref.save
    end
    render_api_ok
  end

  def save_calendars
    if (@module = EasyPageZoneModule.find_by(uuid: params[:module_id]))
      @module.settings ||= {}
      @module.settings[:enabled_calendars] = params[:calendar_ids] ? params[:calendar_ids] : []
      @module.save
    elsif User.current.logged?
      settings = User.current.pref[:easy_calendar]
      settings ||= {}
      settings[:enabled_calendars] = params[:calendar_ids] ? params[:calendar_ids] : []
      User.current.pref[:easy_calendar] = settings
      User.current.pref.save
    end
    render_api_ok
  end

  def find_by_worker
    scope = User.active.non_system_flag.easy_type_internal.sorted
    scope = scope.like(params[:q]) unless params[:q].blank?
    @users = scope.to_a

    respond_to do |format|
      format.html { render :partial => 'find_by_worker_list', :locals => {:users => @users} }
      format.js
    end
  end

  def show
    @settings = User.current.pref[:easy_calendar] if User.current.logged?
    @settings ||= {}
    @settings[:display_from] ||= 6
    @settings[:default_view] ||= 'agendaWeek'
    @settings[:default_view] = 'agendaWeek' if is_mobile_device?
    @settings[:default_column_format] = { month: 'ddd' } if is_mobile_device?
    @users = User.where(id: @settings[:user_ids])
    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def collect_meeting_events!
    meetings = EasyMeeting.arel_table
    includes = if request.format == :ics
                 [:easy_room, { author: :email_address }, { easy_invitations: { user: :email_address } }]
               else
                 [:easy_room, :easy_invitations]
               end

    # includes(:easy_invitations).where(easy_invitations: { user_id: @user.id) will make
    #   meeting#user_invited?(User.current) always return false; we need current user invitations for permissions
    scope = EasyMeeting.includes(includes)
              .where(easy_invitations: { user_id: [@user.id, User.current.id], accepted: [true, nil] })

    if @start_date && @end_date
      scope = scope.where(meetings[:start_time].lt(@end_date)).where(meetings[:end_time].gt(@start_date))
    elsif @start_date
      scope = scope.where(meetings[:start_time].gt(@start_date))
    elsif @end_date
      scope = scope.where(meetings[:end_time].lt(@end_date))
    end

    @events.concat(scope.distinct.to_a.select { |meeting| meeting.user_invited?(@user) })
  end

  def collect_attendance_events!
    includes = [:easy_attendance_activity]
    includes << { user: :email_address } if request.format == :ics

    attendances = @user.easy_attendances.visible.includes(includes).where(easy_attendance_activities: { at_work: false })
    if @start_date && @end_date
      attendances = attendances.between(@start_date, @end_date)
    elsif @start_date
      attendances = attendances.where('easy_attendances.arrival >= ?', @start_date.beginning_of_day)
    elsif @end_date
      attendances = attendances.where('easy_attendances.departure <= ?', @end_date.end_of_day)
    end
    @events.concat(attendances.to_a)
  end

  def parse_date_limits
    @start_date = EasyUtils::DateUtils.from_name(params[:start])
    @start_date ||= DateTime.strptime(params[:start], '%s').to_time rescue nil

    @end_date = EasyUtils::DateUtils.from_name(params[:end])
    @end_date ||= DateTime.strptime(params[:end], '%s').to_time rescue nil
  rescue ArgumentError
  end

  def find_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
