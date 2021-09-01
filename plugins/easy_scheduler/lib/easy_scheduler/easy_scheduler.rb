module EasyScheduler
  class << self
    delegate :url_helpers, to: 'Rails.application.routes'
  end

  def self.easy_extensions?
    Redmine::Plugin.installed?(:easy_extensions)
  end

  def self.easy_project_com?
    Redmine::Plugin.installed?(:easy_project_com)
  end

  def self.easy_calendar?
    Redmine::Plugin.installed?(:easy_calendar)
  end

  def self.easy_attendances?
    easy_extensions? && Redmine::Plugin.installed?(:easy_attendances) && EasyAttendance.enabled?
  end

  def self.easy_crm?
    Redmine::Plugin.installed?(:easy_crm)
  end

  def self.easy_contacts?
    Redmine::Plugin.installed?(:easy_contacts)
  end

  def self.easy_entity_activities?
    easy_extensions? && easy_crm? && easy_contacts?
  end

  def self.easy_money?
    Redmine::Plugin.installed?(:easy_money)
  end

  def self.easy_gantt_resources?
    Redmine::Plugin.installed?(:easy_gantt_resources)
  end

  def self.easy_printable_templates?
    Redmine::Plugin.installed?(:easy_printable_templates)
  end

  def self.easy_theme_designer?
    Redmine::Plugin.installed?(:easy_theme_designer)
  end

  def self.easy_org_chart?
    Redmine::Plugin.installed?(:easy_org_chart)
  end

  def self.combine_by_pipeline?(params)
    return false unless easy_extensions?
    return params[:combine_by_pipeline].to_s.to_boolean if params.key?(:combine_by_pipeline)
    Rails.env.production?
  end

  def self.working_week_days(user=nil)
    if user.is_a?(Integer)
      user = Principal.find_by(id: user)
    elsif user.nil?
      user = User.current
    end

    working_days = user.try(:current_working_time_calendar).try(:working_week_days)
    Array(working_days).map(&:to_i)
  end

  def self.platform
    case
    when easy_project_com?
      'easyproject'
    when easy_extensions?
      'easyredmine'
    else
      'redmine'
    end
  end

  def self.registered_queries
    r = [default_query]
    # r << EasyCrmCaseQuery if easy_crm?
    r
  end

  def self.default_query
    EasySchedulerEasyQuery
  end

  def self.filtered_entities_data_path(query, load_params = nil)
    load_params ||= query.to_params.merge(key: User.current.api_key, format: 'json')
    case query.class.name
    when 'EasySchedulerEasyQuery'
      url_helpers.easy_scheduler_filtered_issues_data_path(load_params)
    when 'EasyCrmCaseQuery'
      return url_helpers.easy_scheduler_filtered_easy_crm_cases_data_path(load_params)
    end
  end

  def self.entity_path(query)
    case query.class.name
    when 'EasySchedulerEasyQuery'
      url_helpers.issue_path('__taskId', key: User.current.api_key, format: :json)
    when 'EasyCrmCaseQuery'
      return url_helpers.easy_crm_case_path('__taskId', key: User.current.api_key, format: :json)
    end
  end
end
