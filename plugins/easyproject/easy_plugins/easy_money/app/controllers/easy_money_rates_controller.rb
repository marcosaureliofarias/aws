class EasyMoneyRatesController < ApplicationController

  before_action :find_project_by_project_id, :only => [:update_rates, :update_rates_to_subprojects, :easy_money_rate_roles, :easy_money_rate_time_entry_activities, :easy_money_rate_users, :inline_update, :bulk_edit, :bulk_update, :projects_select, :projects_update]
  before_action :my_authorize, :only => [:update_rates, :update_rates_to_subprojects, :easy_money_rate_roles, :easy_money_rate_time_entry_activities, :easy_money_rate_users, :inline_update, :bulk_edit, :bulk_update, :projects_select, :projects_update]
  before_action :my_require_admin, :only => [:update_rates, :easy_money_rate_roles, :easy_money_rate_time_entry_activities, :easy_money_rate_users, :inline_update, :bulk_edit, :bulk_update, :projects_select, :projects_update]
  before_action :require_admin, :only => [:update_rates_to_projects]
  before_action :load_users_for_bulk_edit, only: [:bulk_edit, :bulk_update, :projects_select, :projects_update]

  accept_api_auth :easy_money_rate_roles, :easy_money_rate_time_entry_activities, :easy_money_rate_users, :inline_update

  helper :easy_money
  include EasyMoneyHelper

  def update_rates
    case params[:save_setting]
    when 'global_setting', 'self'
      update_rates_core(@project, params[:easy_money_rates])
    when 'all_projects'
      update_rates_to_projects
    when 'self_and_descendants'
      update_rates_to_subprojects
    end

    if request.xhr?
      head :ok
    else
      flash[:notice] = l(:notice_successful_update)

      if @project
        redirect_back_or_default(:controller => 'easy_money_settings', :action => 'project_settings', :project_id => @project)
      else
        redirect_back_or_default(:controller => 'easy_money_settings', :action => 'index')
      end
    end
  end

  def easy_money_rate_roles
    if request.put? && params[:easy_money_rates]
      update_easy_money_rates_from_api('Role')
    end

    if @project.nil?
      @roles = Role.order(:position).all
    else
      @roles = @project.all_members_roles
    end

    respond_to do |format|
      format.api
    end
  end

  def easy_money_rate_time_entry_activities
    if request.put? && params[:easy_money_rates]
      update_easy_money_rates_from_api('Enumeration')
    end

    if @project.nil?
      @activities = TimeEntryActivity.shared.sorted
    else
      @activities = @project.activities.sorted
    end

    respond_to do |format|
      format.api
    end
  end

  def easy_money_rate_users
    if request.put? && params[:easy_money_rates]
      update_easy_money_rates_from_api('Principal')
    end

    @easy_currency_code = params[:easy_currency_code].presence
    @easy_currency_code = EasyCurrency[@easy_currency_code].try(:iso_code) if @easy_currency_code

    if @project.nil?
      @users = User.active.non_system_flag.sorted
    else
      @users = @project.users.non_system_flag.sorted
    end

    respond_to do |format|
      format.api
    end
  end

  def load_affected_projects
    @affected_projects = EasyMoneyRate.affected_projects(params[:type], params[:tab], params[:project_id])
    @affected_projects_count = @affected_projects.count
    @affected_projects = @affected_projects.limit(EasySetting.value('easy_select_limit')) if !params[:show_all]
    respond_to do |format|
      format.js
    end
  end

  def inline_update
    easy_money_rate = EasyMoneyRate.where(rate_type_id: params[:rate_type_id], entity_id: params[:entity_id], entity_type: params[:entity_type], project: @project).first_or_initialize

    @easy_money_rate = EasyMoney::UpdateRate.call(easy_money_rate, easy_money_rate_params)

    if @easy_money_rate.errors.any?
      respond_to do |format|
        format.api  { render_validation_errors(@easy_money_rate) }
      end
    else
      respond_to do |format|
        format.api
      end
    end
  end

  def bulk_update
    easy_money_rates = params.fetch(:easy_money_rate, [])

    @users.each do |user|
      easy_money_rates.each do |easy_money_rate_params|
        update_easy_money_rate_core easy_money_rate_params[:rate_type_id], 'Principal', user.id, @project, easy_money_rate_params[:unit_rate], params[:easy_currency_code]
      end
    end

    redirect_to url_for(controller: 'easy_money_settings', action: @project ? 'project_settings' : 'index', tab: 'EasyMoneyRateUser')
  end

  def projects_select
    @projects = @project ? @project.descendants.active.non_templates.has_module(:easy_money) : Project.non_templates.active.has_module(:easy_money)
  end

  def projects_update
    if params[:project_ids]
      project_ids = params[:project_ids].select{|project_id| project_id.present? }

      if project_ids.any?
        Project.non_templates.active.has_module(:easy_money).where(id: project_ids).each do |project|
          @users.each do |user|
            EasyMoneyRate.where(entity_type: 'Principal', entity_id: user.id, project: @project).each do |easy_money_rate|
              update_easy_money_rate_core easy_money_rate.rate_type_id, 'Principal', user.id, project, easy_money_rate.unit_rate, easy_money_rate.easy_currency_code
            end
          end
        end
      end
    end

    redirect_to url_for(controller: 'easy_money_settings', action: @project ? 'project_settings' : 'index', tab: 'EasyMoneyRateUser')
  end

  private

  def update_rates_to_subprojects
    update_rates_core(@project, params[:easy_money_rates])

    @project.descendants.active.non_templates.has_module(:easy_money).each do |sub_project|
      update_rates_core(sub_project, params[:easy_money_rates])
    end
    # head :ok
  end

  def update_rates_to_projects
    update_rates_core(nil, params[:easy_money_rates])

    project_scope = Project.non_templates.active.has_module(:easy_money)
    EasyMoneyRate.where(project_id: project_scope).where(entity_type: params[:easy_money_rates].keys.uniq).delete_all if params[:easy_money_rates].present?

    # Project.non_templates.active.has_module(:easy_money).pluck(:id).each do |project_id|
    #   update_rates_core(project_id, params[:valid_from], params[:valid_to], params[:easy_money_rates])
    # end

    # head :ok
  end

  def update_rates_core(project, rates)
    default_easy_currency_code = project.try(:easy_currency_code) || EasyCurrency.default_code

    rates.each_pair do |entity_type, entity_rates|
      entity_rates.each_pair do |entity_id, rate_types|
        easy_currency_code = rate_types[:easy_currency_code] || default_easy_currency_code

        rate_types.except(:easy_currency_code).each_pair do |rate_type_id, unit_rate|
          update_easy_money_rate_core(rate_type_id, entity_type, entity_id, project, unit_rate, easy_currency_code)
        end
      end
    end
  end

  def update_easy_money_rate_core(rate_type_id, entity_type, entity_id, project, unit_rate, easy_currency_code)
    scope = EasyMoneyRate.where(rate_type_id: rate_type_id, entity_type: entity_type, entity_id: entity_id, project: project)

    easy_money_rate = scope.first_or_initialize
    easy_money_rate.easy_currency_code = easy_currency_code
    easy_money_rate.unit_rate = unit_rate

    if easy_money_rate.unit_rate.nil?
      easy_money_rate.destroy!
    else
      easy_money_rate.save
    end
  end

  def update_easy_money_rates_from_api(entity_type)
    return if params[:easy_money_rates].nil? || params[:easy_money_rates][:easy_money_rate_type].nil?
    easy_money_rate_types = Array.wrap(params[:easy_money_rates][:easy_money_rate_type])
    default_easy_currency_code = @project.try(:easy_currency_code) || EasyCurrency.default_code

    easy_money_rate_types.each do |easy_money_rate_type|
      easy_money_rates = Array.wrap(easy_money_rate_type[:easy_money_rate])

      easy_money_rates.each do |easy_money_rate|
        easy_currency_code = easy_money_rate[:easy_currency_code].presence || default_easy_currency_code
        update_easy_money_rate_core(easy_money_rate_type[:id], entity_type, easy_money_rate[:id], @project, easy_money_rate[:unit_rate], easy_currency_code)
      end
    end
  end

  def find_project_by_project_id
    @project = Project.find(params[:project_id]) if params[:project_id]
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

  def easy_money_rate_params
    params.require(:easy_money_rate).permit(:unit_rate, :easy_currency_code)
  end

  def load_users_for_bulk_edit
    @users ||= begin
      scope = @project ? @project.users : User
      scope.non_system_flag.easy_type_internal.where(id: params[:ids])
    end
  end

end
