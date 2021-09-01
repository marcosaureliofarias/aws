class EasyRakeTasksController < ApplicationController
  layout 'admin'

  before_action :require_admin, :only => [:index, :execute_tasks]
  before_action :find_easy_rake_task, :except => [:index, :new, :create, :test_mail, :imap_folders, :execute_tasks]
  before_action :new_easy_rake_task, :only => [:new, :create]
  before_action :rake_authorize, :except => [:index, :test_mail, :imap_folders, :execute_tasks]

  accept_api_auth :execute, :execute_tasks

  helper :easy_rake_tasks
  include EasyRakeTasksHelper

  def index
    @tasks        = EasyRakeTask.select("*, GREATEST(COALESCE(next_run_at, '#{Time.now.to_s(:db)}'), '#{Time.now.to_s(:db)}') AS first_executing_time").order('first_executing_time').to_a.select { |t| !t.in_disabled_plugin? }
    last_info_ids = EasyRakeTaskInfo.where(:easy_rake_task_id => @tasks).group(:easy_rake_task_id).maximum(:id).values
    @last_infos   = EasyRakeTaskInfo.where(:id => last_info_ids).inject({}) { |var, info| var[info.easy_rake_task_id] = info; var }

    @running_tasks, @failed_tasks, @ok_tasks, @next_2hours_tasks, @next_24hours_tasks = [], [], [], [], []

    hours_2  = Time.now + 2.hours
    hours_24 = Time.now + 24.hours
    @tasks.each do |task|
      next if !task.active?

      @next_2hours_tasks << task if task.executed_until?(hours_2)
      @next_24hours_tasks << task if task.executed_until?(hours_24)

      last_info = @last_infos[task.id]
      next if last_info.nil?

      @running_tasks << task if last_info.running?
      @failed_tasks << task if last_info.failed?
      @ok_tasks << task if last_info.ok?
    end

    @tasks.sort_by!(&:caption)
  end

  def new
    @task.safe_attributes = params[:easy_rake_task]

    respond_to do |format|
      format.html
    end
  end

  def create
    @task.safe_attributes = params[:easy_rake_task]
    assign_dates

    if @task.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default(:action => :index)
        }
      end
    else
      respond_to do |format|
        format.html { render :action => :new }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    @task.safe_attributes = params[:easy_rake_task]
    assign_dates

    if @task.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default(:action => :index)
        }
      end
    else
      respond_to do |format|
        format.html { render :action => :edit }
      end
    end
  end

  def task_infos
    @task_infos_ok     = @task.easy_rake_task_infos.preload(:easy_rake_task_info_details => :reference).status_ok.limit(10).order("#{EasyRakeTaskInfo.table_name}.started_at DESC")
    @task_infos_failed = @task.easy_rake_task_infos.preload(:easy_rake_task_info_details => :reference).status_failed.limit(10).order("#{EasyRakeTaskInfo.table_name}.started_at DESC")
  end

  def destroy
    if @task.deletable?
      @task.destroy
      flash[:notice] = l(:notice_successful_delete)
    end

    respond_to do |format|
      format.html { redirect_back_or_default :action => 'index' }
    end
  end

  def execute
    @task.class.execute_task(@task)

    redirect_to({ :controller => 'easy_rake_tasks', :action => :task_infos, :id => @task, :back_url => params[:back_url] })
  end

  def execute_tasks
    force   = !!params['force']
    klasses = params['scope'].to_s.split(',').map(&:strip)

    EasyRakeTask.execute_classes(klasses, force)

    head 200
  end

  def easy_rake_task_info_detail_receive_mail
    info_detail = EasyRakeTaskInfoDetailReceiveMail.find(params[:easy_task_info_detail_id])
    render :partial => 'easy_rake_tasks/info_detail/easy_rake_task_info_detail_receive_mail', :locals => { :task => @task, :info_detail => info_detail }
  end

  def easy_rake_task_easy_helpdesk_receive_mail_status_detail
    status = params[:status]
    offset = params[:offset].to_i
    limit  = 10

    details = EasyRakeTaskInfoDetailReceiveMail.joins(:easy_rake_task_info).preload(:easy_rake_task_info).
        where(["#{EasyRakeTaskInfo.table_name}.easy_rake_task_id = ? AND #{EasyRakeTaskInfoDetailReceiveMail.table_name}.status = ?", @task, status]).
        order("#{EasyRakeTaskInfo.table_name}.finished_at DESC").limit(limit).offset(offset)

    respond_to do |format|
      format.js { render :partial => 'easy_rake_tasks/additional_task_info/easy_rake_task_easy_helpdesk_receive_mail_status_detail', :locals => { :task => @task, :details => details, :status => status, :offset => offset + limit } }
    end
  end

  def test_mail
    t = EasyRakeTaskReceiveMail.new
    #return render_403 unless t.visible?
    t.safe_attributes = params[:easy_rake_task]

    begin
      Timeout.timeout(1.minutes) do
        @result = t.test_connection
      end
    rescue StandardError, Timeout::Error => ex
      msg     = Redmine::CodesetUtil.to_utf8(ex.message.to_s.dup, 'UTF-8')
      @result = l(:error_unable_to_connect, :value => msg)
    end

    respond_to do |format|
      format.js
    end
  end

  def imap_folders
    t = EasyRakeTaskReceiveMail.new
    return render_403 unless t.visible?
    t.safe_attributes = params[:easy_rake_task]
    return render_404 if t.settings && t.settings['connection_type'] != 'imap'

    begin
      Timeout.timeout(1.minutes) do
        @result = t.imap_folders
        @error  = l(:label_no_data) if !@result || @result.empty?
      end
    rescue StandardError, Timeout::Error => ex
      msg    = Redmine::CodesetUtil.to_utf8(ex.message.to_s.dup, 'UTF-8')
      @error = l(:error_unable_to_connect, :value => msg)
    end

    respond_to do |format|
      format.js
    end
  end

  private

  def find_easy_rake_task
    @task = EasyRakeTask.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def new_easy_rake_task
    @task = EasyRakeTask.new_subclass_instance(params[:type]) if params[:type]
    return render_404 if @task.nil?
  end

  def rake_authorize
    return render_403 unless @task.visible?
  end

  def assign_dates
    return if params[:next_run_at].nil?

    date = begin
      ; params[:next_run_at][:date].to_date;
    rescue;
      nil;
    end
    time = [params[:next_run_at][:time][:hour], params[:next_run_at][:time][:minute]]

    return if date.nil?
    @task.safe_attributes = { 'next_run_at' => User.current.user_civil_time_in_zone(date.year, date.month, date.day, time[0], time[1]).utc }
  end

end
