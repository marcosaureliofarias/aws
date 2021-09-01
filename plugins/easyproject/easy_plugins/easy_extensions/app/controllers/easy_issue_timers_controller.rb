class EasyIssueTimersController < ApplicationController

  layout 'admin'

  menu_item :easy_issue_timer_settings

  before_action :load_easy_issue_timer_settings, :authorize_global, :except => [:play, :stop, :pause, :get_current_user_timers]
  before_action :find_issue, :authorize, :only => [:play, :stop, :pause]
  before_action :require_login, :only => :get_current_user_timers

  def get_current_user_timers
    respond_to do |format|
      format.json {
        # This should be part of EasyBackgroundService now
        scope = EasyIssueTimer.running(User.current.id)
        render(json: { :running_count => scope.count, :is_active => scope.where(:paused_at => nil).exists? })
      }
      format.js { @easy_issue_timers = EasyIssueTimer.where(:user_id => User.current.id).running.ordered.preload(:issue => :project) }
    end
  end

  def settings
    @statuses = IssueStatus.sorted
  end

  def update_settings
    @statuses = IssueStatus.sorted
    attrs     = params.dup
    attrs.delete_if { |k, v| v.blank? }

    if @project && @easy_setting.project_id.nil?
      @easy_setting = EasySetting.new(:name => :easy_issue_timer_settings, :project_id => @project.id)
    end

    @setting[:active] = attrs[:active].to_boolean

    if @setting[:active]

      @setting[:round] = attrs[:round]

      @setting[:start]             = { :assigned_to_me => attrs[:assigned_to_me] && attrs[:assigned_to_me].to_boolean }
      @setting[:start][:status_id] = attrs[:start_status_id] && IssueStatus.find(attrs[:start_status_id]).id

      @setting[:end]               = {}
      @setting[:end][:assigned_to] = attrs[:assigned_to] && ([:author, :last_user].detect { |o| o == attrs[:assigned_to].to_sym } || User.active.find(attrs[:assigned_to]).id)
      @setting[:end][:status_id]   = attrs[:end_status_id] && IssueStatus.find(attrs[:end_status_id]).id
      @setting[:end][:done_ratio]  = attrs[:done_ratio] && attrs[:done_ratio].to_i
    end

    @easy_setting.value = @setting

    if @easy_setting.save
      flash[:notice] = l(:notice_successful_update)
    else
      flash[:error] = l(:error_update_easy_issue_timer_settings)
    end

    if @project
      redirect_to(settings_project_path(@project, :tab => 'easy_issue_timer'))
    else
      render :settings
    end
  end

  def play
    return render_403 if !EasyIssueTimer.active?(@issue.project)

    @easy_issue_timer = EasyIssueTimer.find_by(:id => params[:timer_id])
    if @easy_issue_timer.nil? && @issue.easy_issue_timers.where(:user_id => User.current.id, :end => nil).any?
      redirect_to @issue
    else
      EasyIssueTimer.transaction do
        @easy_issue_timer ||= @issue.easy_issue_timers.build(:user => User.current, :start => DateTime.now)
        @easy_issue_timer.play!
        @easy_issue_timer.save!

        EasyIssueTimer.where(EasyIssueTimer.arel_table[:id].not_eq(@easy_issue_timer.id)).where(user_id: User.current.id).where(paused_at: nil).includes(:issue).each do |t|
          t.pause!
          @last_paused_easy_issue_timer = t
        end
      end

      respond_to do |format|
        format.html { redirect_to @issue }
        format.js
      end
    end
  end

  def pause
    @easy_issue_timer = EasyIssueTimer.find_by(:id => params[:timer_id])
    if @easy_issue_timer
      @issue = @easy_issue_timer.issue
      @easy_issue_timer.pause!

      respond_to do |format|
        format.html { redirect_to @issue }
        format.js
      end
    else
      render_404
    end
  end

  def stop
    @easy_issue_timer = EasyIssueTimer.find_by(:id => params[:timer_id])
    if @easy_issue_timer
      @easy_issue_timer = @easy_issue_timer.stop!

      respond_to do |format|
        format.html { redirect_to(edit_issue_path(@issue, :issue => { :assigned_to_id => @easy_issue_timer.issue.assigned_to_id,
                                                                      :status_id      => @easy_issue_timer.issue.status_id,
                                                                      :done_ratio     => @easy_issue_timer.issue.done_ratio },
                                                  :time_entry    => { :hours           => @easy_issue_timer.hours,
                                                                      :easy_range_from => @easy_issue_timer.computed_start.to_time,
                                                                      :easy_range_to   => @easy_issue_timer.computed_end.to_time })) }
      end
    else
      respond_to do |format|
        format.html { redirect_to @issue }
      end
    end
  end

  def destroy
    @easy_issue_timer = EasyIssueTimer.find(params[:id])
    @easy_issue_timer.destroy

    respond_to do |format|
      format.html { redirect_back_or_default(issue_path(@easy_issue_timer.issue)) }
      format.js
    end
  end

  private

  def load_easy_issue_timer_settings
    @project = Project.find(params[:project_id]) if params[:project_id]

    scope = EasySetting.where(:name => 'easy_issue_timer_settings')
    if @project
      scope = scope.where(:project_id => @project.id)
    else
      scope = scope.where(:project_id => nil)
    end

    @easy_setting = scope.first || EasySetting.new(:name => 'easy_issue_timer_settings', :project_id => @project)

    @easy_setting.reload unless @easy_setting.new_record?

    @setting = @easy_setting.value || Hash.new
  end

end
