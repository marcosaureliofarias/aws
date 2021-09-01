class EasyAttendancesController < ApplicationController

  before_action :find_easy_attendance, only: [:show, :edit, :update, :destroy, :departure]
  before_action :authorize_global, except: [:change_activity, :overview, :layout]
  before_action :ensure_bulk_create, only: [:create]
  before_action :build_easy_attendance, only: [:create, :update, :change_activity, :check_vacation_limit]
  before_action :enabled_this
  before_action :load_journals, only: [:show], if: -> { request.format.html? }

  accept_api_auth :show, :create, :index, :update, :destroy
  accept_rss_auth :index

  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper
  helper :journals
  include JournalsHelper
  helper :easy_journal
  include EasyJournalHelper
  include EasyIcalHelper
  helper :easy_attendances
  include EasyAttendancesHelper

  include EasyUtils::DateUtils

  EasyExtensions::EasyPageHandler.register_for(self, {
      page_name:   'easy-attendances-overview',
      path:        proc { easy_attendances_overview_path(t: params[:t]) },
      show_action: :overview,
      edit_action: :layout
  })

  # POST => :create; GET => :list
  def index
    retrieve_query(EasyAttendanceQuery, false, { :use_session_store => true })
    if in_mobile_view? && (params[:tab].blank? || params[:tab] == 'calendar')
      params[:tab] = 'list'
    elsif !@query.new_record? && params[:tab].blank?
      params[:tab] = @query.outputs.include?('list') ? 'list' : 'calendar'
    elsif %w(csv pdf xlsx atom ics).include?(params[:format]) || api_request?
      params[:tab] = 'list'
    end

    @user_ids     = @query.filters['user_id'].try(:[], :values).to_a
    @query.output = params[:tab]

    if params[:tab] == 'list'
      @query.default_list_columns << 'user'
      @query.display_outputs_select_on_index = false

      sort_init(@query.sort_criteria_init)
      sort_update(@query.sortable_columns)

      @attendances = prepare_easy_query_render

      respond_to do |format|
        format.html {
          render_easy_query_html
        }
        format.csv { send_data(export_to_csv(@attendances, @query), filename: get_export_filename(:csv, @query)) }
        format.pdf { send_file_headers! :type => 'application/pdf', :filename => get_export_filename(:pdf, @query) }
        format.xlsx { send_data(export_to_xlsx(@attendances, @query), :filename => get_export_filename(:xlsx, @query)) }
        format.atom { render_feed(@entities, { template: 'easy_attendances/attendance_feed', title: "#{Setting.app_title}: #{l(:label_easy_attendance_plural)}" }) }
        format.ics { send_data(easy_attendances_to_ical(@entities), :filename => get_export_filename(:ics, @query), :type => Mime[:ics].to_s + '; charset=utf-8') }
        format.api {
          @entity_count   = @query.entity_count
          @offset, @limit = api_offset_and_limit
        }
      end
    elsif params[:tab].blank? || params[:tab] == 'calendar'
      @query.display_filter_columns_on_index  = false
      @query.display_filter_group_by_on_index = false
      @query.display_filter_sort_on_index     = false
      @query.display_filter_settings_on_index = false
      @query.group_by                         = nil

      unless params[:start_date].blank?
        @start_date = begin
          ; params[:start_date].to_date;
        rescue;
        end
      end

      if @start_date
        @query.filters.delete('departure')
        @query.filters['arrival'] = HashWithIndifferentAccess.new(:operator => 'date_period_2', :values => HashWithIndifferentAccess.new(:from => @start_date.beginning_of_month, :to => @start_date.end_of_month, :period => 'current_month'))
      end

      @query.export_formats = {}

      @start_date ||= @query.create_entity_scope(order: [arrival: :desc]).limit(1).pluck(:arrival).first&.localtime&.to_date
      @start_date ||= User.current.today
      @calendar   = EasyAttendances::Calendar.new(@start_date, current_language, :month)
      @entities   = @query.create_entity_scope(order: nil).
          where(["(#{EasyAttendance.table_name}.arrival BETWEEN ? AND ?)", @calendar.startdt, @calendar.enddt.end_of_day]).
          order([User.fields_for_order_statement, "#{EasyAttendance.table_name}.arrival"]).to_a

      if @query.valid?
        @calendar.events = @entities
      end
      if @user_ids.any?
        if @user_ids.size == 1
          user_id = @user_ids.first
        end
        user_id = User.current.id if @user_ids.include?('me')

        @easy_user_working_time_calendar = user_id && EasyUserWorkingTimeCalendar.find_by(:user_id => user_id) || EasyUserWorkingTimeCalendar.default
      end
      respond_to do |format|
        format.html
      end
    else
      render_406
    end
  end

  def report
    @modul_uniq_id = params[:uuid] || 'main'
    @hide_form     = params[:hide_form] == '1' || false

    params[:tab] = 'report'

    @saved_params               = params[:report] || {}
    @saved_params[:period_type] ||= '2'
    @saved_params[:from]        ||= Date.today.beginning_of_month
    @saved_params[:to]          ||= Date.today
    @saved_params[:users]       ||= [User.current.id]

    date_range = get_date_range(@saved_params[:period_type], @saved_params[:period], @saved_params[:from], @saved_params[:to], @saved_params[:period_days])
    @from, @to = date_range[:from], date_range[:to]

    @activities = EasyAttendanceActivity.sorted
    @user_ids   = @saved_params[:users]

    if @saved_params[:users].present? && User.current.allowed_to_globally?(:view_easy_attendance_other_users)
      @selected_user_ids = []
      @selected_users    = Principal.where(id: @saved_params[:users].map(&:to_i)).to_a
      @selected_users.each do |p|
        if p.is_a?(User)
          @selected_user_ids << p.id
        elsif p.is_a?(Group)
          @selected_user_ids.concat(p.users.pluck(:id))
        end
      end
      @selected_user_ids.uniq!
    else
      @selected_user_ids = [User.current.id]
    end

    @reports = []
    User.active.non_system_flag.sorted.where(id: @selected_user_ids).each do |user|
      @reports << EasyAttendanceReport.new(user, @from, @to)
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def detailed_report
    retrieve_query(EasyAttendanceUserQuery)
    sort_init(@query.sort_criteria_init)
    sort_update(@query.sortable_columns)
    @query.output                          = 'list'
    @query.display_outputs_select_on_index = false
    @query.add_filter('status', '=', [User::STATUS_ACTIVE.to_s]) unless @query.has_filter?('status')

    prepare_easy_query_render(nil, limit: nil)

    respond_to do |format|
      format.html {
        render_easy_query
      }
      format.api
      format.csv { send_data(export_to_csv(@entities, @query), filename: get_export_filename(:csv, @query)) }
      format.pdf { send_data(export_to_pdf(@entities, @query), :filename => get_export_filename(:pdf, @query)) }
      format.xlsx { send_data(export_to_xlsx(@entities, @query), :filename => get_export_filename(:xlsx, @query)) }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.api
    end
  end

  def new
    arrival = params[:arrival_at].to_date rescue User.current.today
    departure = params[:departure].to_date rescue nil if params[:departure]
    departure ||= arrival

    @easy_attendance                          = EasyAttendance.new(user: User.current)
    @easy_attendance.attendance_date          = arrival
    @easy_attendance.arrival                  = @easy_attendance.morning(arrival)
    @easy_attendance.departure                = @easy_attendance.evening(departure)
    @easy_attendance.easy_attendance_activity = EasyAttendanceActivity.default
    @easy_attendance.set_default_range

    respond_to do |format|
      format.js
      format.html { render layout: !request.xhr? }
    end
  end

  def arrival
    @only_arrival                             = true
    @easy_attendance                          = EasyAttendance.new(:user => User.current)
    @easy_attendance.arrival                  = Time.now
    @easy_attendance.easy_attendance_activity = EasyAttendanceActivity.default

    respond_to do |format|
      format.js
    end
  end

  def departure
    if EasyAttendance.create_departure(@easy_attendance, current_user_ip)
      flash[:notice] = l(:notice_easy_attendance_departured, :at => format_time(@easy_attendance.departure))
      redirect_back_or_default easy_attendances_path
    else
      render 'edit'
    end
  end

  def create
    @easy_attendance.current_user_ip = current_user_ip
    @easy_attendance.ensure_easy_attendance_non_work_activity

    if @easy_attendance.errors.blank? && @easy_attendance.save
      @easy_attendance.after_create_send_mail
      Redmine::Hook.call_hook(:controller_easy_attendances_after_create, { easy_attendance: @easy_attendance })
      respond_to do |format|
        format.html do
          flash[:notice]  = l(:notice_successful_create)
          flash[:warning] = @easy_attendance.warnings.join(', ') if @easy_attendance.warnings.any?
          redirect_back_or_default({ :controller => 'easy_attendances', :action => 'index' })
        end
        format.api { render :action => 'show' }
        format.js
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api { render_validation_errors(@easy_attendance) }
        format.js { render action: 'new' }
      end
    end
  end

  def bulk_create
    @user_ids         = params[:easy_attendance][:user_id]
    error             = false
    @easy_attendances = []
    EasyAttendance.transaction do
      @user_ids.each do |user_id|
        params[:easy_attendance][:user_id] = user_id
        build_easy_attendance
        @easy_attendance.current_user_ip = current_user_ip
        @easy_attendance.ensure_easy_attendance_non_work_activity
        stash_for_delivery = @easy_attendance.dup
        if @easy_attendance.errors.blank? && @easy_attendance.save
          @easy_attendances << @easy_attendance
          @easy_attendance.after_create_send_mail
          @easy_attendance = nil
        else
          error = true
          raise ActiveRecord::Rollback
          break
        end
      end
    end

    if error
      respond_to do |format|
        format.html { render action: 'new' }
        format.api { render_validation_errors(@easy_attendance) }
        format.js { render action: 'new' }
      end
    else
      Redmine::Hook.call_hook(:controller_easy_attendances_after_bulk_create, { easy_attendances: @easy_attendances })
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default({ :controller => 'easy_attendances', :action => 'index' })
        end
        format.api do
          @easy_attendance = @easy_attendances.first
          render action: 'show'
        end
        format.js { render action: 'bulk_create' }
      end
    end
  end

  def edit
    @easy_attendance.arrival = Time.now if @easy_attendance.arrival.blank?
    if @easy_attendance.departure.blank?
      arrival                    = @easy_attendance.arrival.localtime
      @easy_attendance.departure = Time::local(arrival.year, arrival.month, arrival.day, Time.now.hour, Time.now.min)
    end
    respond_to do |format|
      format.js
      format.html { render layout: !request.xhr? }
    end
  end

  def update
    @easy_attendance.current_user_ip = current_user_ip
    @easy_attendance.ensure_easy_attendance_non_work_activity

    if @easy_attendance.errors.blank? && @easy_attendance.save
      @easy_attendance.after_update_send_mail if @easy_attendance.previous_changes.any?
      call_hook(:controller_easy_attendances_after_update, { easy_attendance: @easy_attendance })
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default({ :controller => 'easy_attendances', :action => 'index', :tab => params[:tab] })
        end
        format.api { render action: :show }
        format.js
      end
    else
      respond_to do |format|
        format.html do
          render :action => 'edit'
        end
        format.js { render action: 'edit' }
        format.api { render_validation_errors(@easy_attendance) }
      end
    end
  end

  def bulk_update
    @easy_attendances = EasyAttendance.where(:id => params[:ids]).order(:arrival)
    attributes        = parse_params_for_bulk_entity_attributes(params[:easy_attendance])
    errors            = Array.new
    approval_stash    = []
    @easy_attendances.each do |easy_attendance|
      easy_attendance.init_journal(User.current)
      easy_attendance.safe_attributes = attributes
      if easy_attendance.save
        approval_stash << easy_attendance if easy_attendance.easy_attendance_activity.approval_required? && easy_attendance.previous_changes.any?
      else
        errors << "##{easy_attendance.id} : #{easy_attendance.errors.full_messages.join(', ')}"
      end
    end
    if errors.blank?
      flash[:notice] = l(:notice_successful_update)
    else
      flash[:error] = (l(:error_bulk_update_save, :count => errors.size) + '<br>' + errors.join('<br>')).html_safe
    end
    EasyAttendance.deliver_pending_attendances(approval_stash)
    redirect_back_or_default({ :controller => 'easy_attendances', :action => 'index', :tab => 'list' })
  end

  def bulk_cancel
    @easy_attendances                = EasyAttendance.where(:id => params[:ids]).order(:arrival)
    errors                           = []
    cancel_requests_email_queue      = []
    canceled_attendances_email_queue = []

    @easy_attendances.each do |easy_attendance|
      direct_cancel    = easy_attendance.direct_cancel?
      cancel_requested = easy_attendance.cancel_request

      if cancel_requested && !direct_cancel
        cancel_requests_email_queue << easy_attendance
      elsif cancel_requested && direct_cancel && easy_attendance.user != User.current
        canceled_attendances_email_queue << easy_attendance
      elsif !cancel_requested
        errors << "##{easy_attendance.id} : #{l(:error_cannot_cancel_attendance)}"
      end
    end
    EasyAttendance.deliver_pending_attendances(cancel_requests_email_queue) if cancel_requests_email_queue.present?
    EasyAttendance.deliver_approval_response(canceled_attendances_email_queue, nil) if canceled_attendances_email_queue.present?

    if errors.blank?
      Redmine::Hook.call_hook(:controller_easy_attendances_after_bulk_update, { easy_attendances: @easy_attendances })
      flash[:notice] = l(:notice_successful_update)
    else
      flash[:error] = (l(:error_bulk_update_save, :count => errors.size) + '<br>' + errors.join('<br>')).html_safe
    end
    redirect_back_or_default({ :controller => 'easy_attendances', :action => 'index', :tab => params[:tab] })
  end

  def destroy
    EasyAttendance.delete_easy_attendances([@easy_attendance])

    respond_to do |format|
      format.html do
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default({ :controller => 'easy_attendances', :action => 'index', :tab => params[:tab] })
      end
      format.api { render_api_ok }
    end
  end

  def bulk_destroy
    @easy_attendances = EasyAttendance.where(:id => params[:ids]).order(:arrival)
    EasyAttendance.delete_easy_attendances(@easy_attendances)

    flash[:notice] = l(:notice_successful_delete)
    redirect_back_or_default({ :controller => 'easy_attendances', :action => 'index', :tab => 'list' })
  end

  # RESTFUL END


  def load_journals
    @journals = @easy_attendance.journals.preload(:journalized, :user, :details).reorder("#{Journal.table_name}.id ASC").to_a
    @journals.reverse! if User.current.wants_comments_in_reverse_order?
  end

  def change_activity
    @activity                        = @easy_attendance.easy_attendance_activity
    @easy_attendance.set_default_range
    @easy_attendance.attendance_date ||= (@easy_attendance.arrival || User.current.today).to_date
    @easy_attendance.arrival         ||= @easy_attendance.morning(@easy_attendance.attendance_date)
    @easy_attendance.departure       ||= @easy_attendance.evening(@easy_attendance.attendance_date)
    respond_to do |format|
      format.js
    end
  end

  def new_notify_after_arrived
    @me                           = User.current
    @user                         = User.find(params[:user_id])
    @easy_attendance_notify_count = EasyAttendanceUserArrivalNotify.where(:user_id => @user.id, :notify_to_id => @me.id).count
  end

  def create_notify_after_arrived
    @me   = User.current
    @user = User.find(params[:user_id])
    EasyAttendanceUserArrivalNotify.create(:user_id => @user.id, :notify_to_id => @me.id, :message => params[:notify_message])

    redirect_to @user, :notice => l(:notice_successful_create)
  end

  # This should be part of EasyBackgroundService now
  def statuses
    result = {}
    if EasyAttendance.enabled?
      users = User.where(id: Array(params[:user_ids])).to_a

      User.load_current_attendance(users)
      User.load_last_today_attendance_to_now(users)

      users.each do |user|
        result[user.id] = easy_attendance_user_status_indicator(user)
      end
    end

    render json: result
  end

  def approval
    @easy_attendances = EasyAttendance.approval_required
    @easy_attendances = @easy_attendances.where(id: params[:ids]) if params[:ids]
    @easy_attendances = @easy_attendances.where(user_id: params[:user_ids]) if params[:user_ids]

    @approve = params[:approve].present? ? params[:approve].to_i : nil
    @title   = l("approval-#{@approve || 1}", scope: :easy_attendance)
    @is_exceeded_attendance = EasyAttendance.check_limit_exceeded(@easy_attendances)

    respond_to do |format|
      format.js
      format.html do
        if @easy_attendances.empty?
          flash[:warning] = l(:text_no_unresolved_attendances)
          redirect_to easy_attendances_path(tab: 'list')
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def approval_save
    attendances = EasyAttendance.approve_attendances(params[:ids], params[:approve], params[:notes])
    if attendances[:saved].empty?
      error_messages = if attendances[:unsaved].empty?
                         [l(:not_possible_to_approve_all_attendances, scope: :easy_attendance)]
                       else
                         attendances[:unsaved].map { |a| a.errors.full_messages }.flatten
                       end
    end

    respond_to do |format|
      format.html do
        if error_messages
          flash[:error] = error_messages.join('<br />').html_safe
        else
          flash[:notice] = l(:notice_successful_update)
        end
        redirect_back_or_default(easy_attendances_path(tab: 'list'))
      end
      format.json do
        if error_messages
          render_api_errors(error_messages)
        else
          render json: { updated_untity_ids: attendances[:saved].map(&:id) }
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def check_vacation_limit
    invalid_attendances = []

    if params[:easy_attendance]
      user_ids = Array.wrap(params[:easy_attendance][:user_id].presence || User.current.id)
      users = User.active.visible.where(id: user_ids)

      users.each do |user|
        @easy_attendance.user = user
        invalid_attendances << @easy_attendance.dup if !@easy_attendance.easy_attendance_vacation_limit_valid?(true) && !@easy_attendance.confirmation.to_boolean
      end
    end

    if invalid_attendances.any?
      message = ''
      if @easy_attendance.user_id == User.current.id && user_ids.size == 1
        message += "<p>#{ l(:label_easy_attendance_dialog_for_confirm, activity: @easy_attendance.easy_attendance_activity.name) }</p>"
      else
        message += "<p>#{ l(:users_vacation_limit_exceed, scope: [:easy_attendance], activity: @easy_attendance.easy_attendance_activity.name, users: invalid_attendances.map(&:user).join(', ')) }</p>"
      end
    end

    respond_to do |format|
      format.json { render(json: { message: message, is_valid: !invalid_attendances.any? }) }
    end
  end

  private

  def ensure_bulk_create
    if params[:easy_attendance] && params[:easy_attendance][:user_id].is_a?(Array)
      if params[:easy_attendance][:user_id].count > 1
        return bulk_create
      else
        params[:easy_attendance][:user_id] = params[:easy_attendance][:user_id].first
      end
    end
  end

  def find_easy_attendance
    @easy_attendance = EasyAttendance.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def build_easy_attendance
    @easy_attendance ||= EasyAttendance.new
    @easy_attendance.init_journal(User.current, params[:notes]) unless @easy_attendance.new_record?
    @easy_attendance.safe_attributes = params[:easy_attendance]
    @easy_attendance.user_id         ||= User.current.id
    @easy_attendance.arrival         = params[:arrival] if params[:arrival].present?
    assign_departure_date
    @easy_attendance.non_work_start_time = params[:non_work_start_time].presence
    @easy_attendance.approval_status     ||= (params[:approval_status] if params[:approval_status].present?)
  end

  def enabled_this
    unless EasyAttendance.enabled?
      render_403
    end
  end

  def assign_departure_date
    departure = params[:departure].presence
    if !departure.is_a?(String) && params[:preselected_departure_date].presence &&
        (!@easy_attendance.activity&.specify_by_time? || params[:is_repeating])
      departure         ||= {}
      departure['date'] = params[:preselected_departure_date]
    end

    @easy_attendance.departure = departure if departure
  end

end
