class EasyCrmSettingsController < ApplicationController

  menu_item :easy_crm

  before_action :find_project, :only => [:project_index, :save_project_settings]
  before_action :authorize, :only => [:project_index, :save_project_settings]
  before_action :require_admin, :only => [:index, :save_global_settings]

  layout :set_layout

  helper :easy_rake_tasks
  include EasyRakeTasksHelper
  helper :projects
  include ProjectsHelper
  helper :issues
  include IssuesHelper
  helper :easy_setting
  include EasySettingHelper
  helper :easy_crm
  include EasyCrmHelper
  helper :users
  helper :easy_user_targets

  def index
    @tab = params[:tab]
    case @tab
      when 'easy_user_targets'
        @easy_user_target_pages, @users = paginate(User.where(has_target: true).sorted, per_page: per_page_option)
      when 'easy_crm_kanban_settings'
        @all_statuses = EasyCrmCaseStatus.sorted
        @easy_crm_kanban_settings = easy_crm_case_kanban_project_settings
      else
        @easy_crm_case_statuses = EasyCrmCaseStatus.sorted
    end
  end

  def project_index
    params[:tab] = 'easy_crm'
    @easy_crm_case_statuses = EasyCrmCaseStatus.sorted

    @tasks = EasyRakeTaskEasyCrmReceiveMail.where(project_id: @project.id)
    last_info_ids = EasyRakeTaskInfo.where(:easy_rake_task_id => @tasks).group(:easy_rake_task_id).maximum(:id).values
    @last_infos = EasyRakeTaskInfo.where(:id => last_info_ids).inject({}) { |var, info| var[info.easy_rake_task_id] = info; var }

    @easy_crm_case_mail_templates = EasyCrmCaseMailTemplate.where(project_id: @project.id).order(:subject)
    @easy_crm_case_mail_template = EasyCrmCaseMailTemplate.new
    respond_to do |format|
      format.html
    end
  end

  def save_project_settings
    before_currency = EasySetting.value('crm_currency', @project)

    save_easy_settings(@project)

    after_currency = EasySetting.value('crm_currency', @project)

    if before_currency != after_currency
      EasyCrmCase.where(:project_id => @project.id).update_all(:currency => after_currency)
    end

    redirect_back_or_default easy_crm_settings_project_path(@project)
  end

  def save_global_settings
    save_easy_settings
    redirect_back_or_default easy_crm_settings_global_path
  end

  private

  def set_layout
    if @project.nil?
      'admin'
    else
      'base'
    end
  end

end
