class EasyMoneySettingsController < ApplicationController
  layout :set_layout

  menu_item :easy_money

  before_action :find_project_by_project_id, :only => [:project_settings, :move_rate_priority, :update_settings, :recalculate, :update_settings_to_subprojects, :easy_money_rate_priorities]
  before_action :my_authorize, :only => [:project_settings, :move_rate_priority, :update_settings, :recalculate, :easy_money_rate_priorities, :easy_money_rate_roles, :easy_money_rate_time_entry_activities, :easy_money_rate_users]
  before_action :my_require_admin, :only => [:index, :custom_field_new, :custom_field_edit, :custom_field_destroy, :move_rate_priority, :update_settings, :update_settings_to_projects, :recalculate, :easy_money_rate_priorities, :easy_money_rate_roles, :easy_money_rate_time_entry_activities, :easy_money_rate_users]

  before_action :configure_tab_content, on: [:index, :project_settings]

  accept_api_auth :easy_money_rate_priorities

  helper :easy_money
  include EasyMoneyHelper
  helper :easy_money_settings
  include EasyMoneySettingsHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper

  def index
    @custom_fields_by_type = CustomField.where(:type => ['EasyMoneyExpectedExpenseCustomField', 'EasyMoneyExpectedRevenueCustomField', 'EasyMoneyOtherExpenseCustomField', 'EasyMoneyOtherRevenueCustomField']).order(:position).all.group_by {|f| f.class.name }
    @tab = params[:tab] || 'EasyMoneyExpectedExpenseCustomField'
    @different_settings = {}
    @different_settings[:revenues] = EasyMoneySettings.includes(:project).where("#{EasyMoneySettings.table_name}.name = 'revenues_type' AND #{EasyMoneySettings.table_name}.value <> '#{EasyMoneySettings.find_settings_by_name('revenues_type',nil)}' AND #{EasyMoneySettings.table_name}.project_id IS NOT NULL").collect{|revenues| revenues.project&.name}.compact.join(', ')
    @different_settings[:expenses] = EasyMoneySettings.includes(:project).where("#{EasyMoneySettings.table_name}.name = 'expenses_type' AND #{EasyMoneySettings.table_name}.value <> '#{EasyMoneySettings.find_settings_by_name('expenses_type',nil)}' AND #{EasyMoneySettings.table_name}.project_id IS NOT NULL").collect{|expenses| expenses.project&.name}.compact.join(', ')

    all_affected_projects = EasyMoneyRate.affected_projects('global', params[:tab], nil)
    @affected_projects_count = all_affected_projects.count
    @affected_projects = all_affected_projects.limit(EasySetting.value('easy_select_limit'))
  end

  def project_settings
    @affected_projects = EasyMoneyRate.affected_projects('self', params[:tab], @project.id)
    @affected_projects_count = @affected_projects.count

    case params[:tab]
    when'EasyMoneyRateUser'
      flash.now[:warning] = l(:label_easy_money_settings_use_global_user_rates) if !EasyMoneyRate.exists?(project_id: @project.id, entity_type: 'Principal')
    when 'EasyMoneyRateTimeEntryActivity'
      flash.now[:warning] = l(:label_easy_money_settings_use_global_activity_rates) if !EasyMoneyRate.exists?(project_id: @project.id, entity_type: 'Enumeration')
    when 'EasyMoneyRateRole'
      flash.now[:warning] = l(:label_easy_money_settings_use_global_role_rates) if !EasyMoneyRate.exists?(project_id: @project.id, entity_type: 'Role')
    when 'EasyMoneyOtherSettings'
      flash.now[:warning] = l(:label_easy_money_settings_use_global_setting) if !EasyMoneySettings.exists?(project_id: @project.id)
    end
  end

  def move_rate_priority
    @rate_priority = EasyMoneyRatePriority.find(params[:id])
    @rate_priority.safe_attributes = params[:easy_money_rate_priority]
    @rate_priority.save

    respond_to do |format|
      format.api { render_api_ok }
    end
  end

  def update_settings
    case params[:save_setting]
      when 'global_setting', 'self'
        update_settings_core(@project)
      when 'all_projects'
        update_settings_to_projects
      when 'self_and_descendants'
        update_settings_to_subprojects
    end

    flash[:notice] = l(:notice_successful_update)
    if @project
      redirect_to :action => 'project_settings', :tab => 'EasyMoneyOtherSettings', :project_id => @project
    else
      redirect_to :action => 'index', :tab => 'EasyMoneyOtherSettings'
    end

  end

  def update_settings_to_projects
    update_settings_core
    Project.active.non_templates.has_module(:easy_money).each do |project|
      update_settings_core(project)
    end
    #redirect_to :action => 'index', :tab => 'EasyMoneyOtherSettings'
  end

  def update_settings_to_subprojects
    update_settings_core(@project)
    @project.descendants.non_templates.active.has_module(:easy_money).each do |project|
      update_settings_core(project)
    end
    # redirect_to :action => 'index', :tab => 'EasyMoneyOtherSettings'
  end

  def recalculate
    scope = @project ? @project.self_and_descendants : Project.non_templates.has_module(:easy_money)

    scope.pluck(:id).each{|project_id| expire_fragment("easy_money_project_overview_project_#{project_id}")}

    flash[:notice] = l(:notice_easy_money_recalculate)

    if params[:back_url]
      redirect_to params[:back_url]
    else
      redirect_to :back
    end
  end

  def easy_money_rate_priorities
    if request.put? && params[:easy_money_rate_priority] && params[:easy_money_rate_priority][:id]
      params[:easy_money_rate_priority].delete_if { |k| ['project_id', 'rate_type_id', 'entity_type'].include?(k) }
      @rate_priority = EasyMoneyRatePriority.find(params[:easy_money_rate_priority][:id])
      @rate_priority.safe_attributes = params[:easy_money_rate_priority]
      @rate_priority.save
    end

    respond_to do |format|
      format.api
    end
  end

  private

  def find_project_by_project_id
    @project = Project.find(params[:project_id]) if params[:project_id]
  end

  def set_layout
    @project ? 'base' : 'admin'
  end

  def my_authorize
    unless @project.nil?
      authorize
    end
  end

  def my_require_admin
    unless @project || User.current.admin?
      authorize
    end
  end

  def update_settings_core(project = nil)
    easy_money_settings = EasyMoneySettings.project_settings_names

    unless project
      easy_money_settings += EasyMoneySettings.global_settings_names
    end

    easy_money_settings.each do |name|
      update_setting_core(project, name)
    end
  end

  def update_setting_core(project, name)
    easy_money_setting = EasyMoneySettings.where(name: name, project: project).first_or_initialize

    if easy_money_setting.name.in? EasyMoneySettings::SETTINGS_WITH_PRICE_RATE
      easy_money_setting.value = params[:settings][name][:value]
      easy_money_setting.easy_currency_code = params[:settings][name][:easy_currency_code]
    else
      easy_money_setting.value = params[:settings][name]
    end

    easy_money_setting.save!
  end

  def configure_tab_content
    tab = params[:tab] || 'EasyMoneyExpectedExpenseCustomField'

    method = "configure_tab_#{tab.underscore}"
    if respond_to?(method, true)
      __send__ method
    end
  end

  def configure_tab_easy_money_rate_user
    retrieve_query EasyMoneyUserRateQuery
    sort_init @query.sort_criteria_init
    sort_update @query.sortable_columns

    prepare_easy_query_render
  end


  # def convert_project_expected_payroll_expenses(project_id, expected_payroll_expense_rate)
  #   if project_id
  #     project = Project.find(project_id)
  #
  #     if project && (expected_hours = project.expected_hours)
  #       price = expected_hours.hours.to_f * expected_payroll_expense_rate.to_f
  #
  #       if expected_payroll_expenses = project.expected_payroll_expenses
  #         expected_payroll_expenses.price = price
  #         expected_payroll_expenses.save
  #       else
  #         project.expected_payroll_expenses.create(:price => price)
  #       end
  #     end
  #   end
  # end

end
