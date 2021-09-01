class EasyCrmChartsController < ApplicationController
  include EasyQueryHelper
  include EasyUtils::DateUtils

  before_action :find_easy_page_zone_module, only: [:user_performance_chart, :pie_chart_from_custom_field, :user_compare_chart]
  before_action :find_optional_project_from_module, only: [:user_performance_chart, :pie_chart_from_custom_field, :user_compare_chart]
  before_action :easy_crm_charts_authorize

  def user_performance_chart
    @users_settings = (@easy_page_zone_module.settings['users'] || {}).select{|usr_id, sett| sett['show'] == '1'}

    @users = User.where(id: @users_settings.keys).to_a
    @colors = @users_settings.collect{|k, v| v['color']}
    @currency = @easy_page_zone_module.settings['currency']
    shift = params[:shift].to_i

    if params[:period].blank?
      period = @easy_page_zone_module.settings['period'] || 'months'
    else
      period = params[:period].to_s
    end

    if @easy_page_zone_module.settings['columns'].blank?
      columns_no = 3
    else
      columns_no = @easy_page_zone_module.settings['columns'].to_i - 1
    end

    columns_no = 1 if columns_no < 1
    columns_no = 13 if columns_no > 13

    case period
    when 'months'
      date_from ||= Date.today.beginning_of_month + (columns_no * shift).months
      date_to ||= (date_from + columns_no.months).end_of_month
    when 'weeks'
      date_from ||= Date.today.beginning_of_week(EasyUtils::DateUtils.day_of_week_start) + (columns_no * shift).weeks
      date_to ||= (date_from + columns_no.weeks).end_of_week
    when 'days'
      date_from ||= Date.today + (columns_no * shift).days
      date_to ||= date_from + columns_no.days
    end

    @price_sums = Hash.new{|hash, key| hash[key] = Hash.new}

    date_from.upto(date_to).each do |date|
      @users_settings.each_key do |user_id|
        case period
        when 'months'
          @price_sums[user_id]["#{date.month} / #{date.year}"] = 0.0
        when 'weeks'
          @price_sums[user_id]["#{date.cweek} / #{date.year}"] = 0.0
        when 'days'
          @price_sums[user_id][format_date(date)] = 0.0
        end
      end
    end

    scope = EasyCrmCase.where(contract_date: date_from..date_to)
    scope = scope.where(assigned_to_id: @users_settings.keys.map { |user_id| user_id == '0' ? nil : user_id })
    scope = scope.where("#{EasyCrmCase.table_name}.price > 0")
    scope = scope.where(easy_crm_case_status_id: @easy_page_zone_module.settings['easy_crm_case_status_id']) unless @easy_page_zone_module.settings['easy_crm_case_status_id'].blank?
    scope = scope.where(:project_id => @project.id) if @project

    scope.to_a.each do |easy_crm_case|
      user_id = easy_crm_case.assigned_to_id.nil? ? '0' : easy_crm_case.assigned_to_id.to_s
      order_date = easy_crm_case.contract_date
      case period
      when 'months'
        @price_sums[user_id]["#{order_date.month} / #{order_date.year}"] += easy_crm_case.price(@currency).to_f     # * EasySetting.value('crm_currency_rate', @project).to_f
      when 'weeks'
        @price_sums[user_id]["#{order_date.cweek} / #{order_date.year}"] += easy_crm_case.price(@currency).to_f# * EasySetting.value('crm_currency_rate', @project).to_f
      when 'days'
        @price_sums[user_id][format_date(order_date)] += easy_crm_case.price(@currency).to_f# * EasySetting.value('crm_currency_rate', @project).to_f
      end
    end

    respond_to do |format|
      format.json
    end
  end

  def pie_chart_from_custom_field
    scope = EasyCrmCase.joins(:custom_values).where(custom_values: {custom_field_id: @easy_page_zone_module.settings['custom_field']})
    scope = scope.where(easy_crm_case_status_id: @easy_page_zone_module.settings['easy_crm_case_status_id']) unless @easy_page_zone_module.settings['easy_crm_case_status_id'].blank?
    scope = scope.group("#{CustomValue.table_name}.value")
    scope = scope.where(project_id: @project.id) if @project

    if dates = self.get_date_range(@easy_page_zone_module.settings['period_type'], @easy_page_zone_module.settings['period'], @easy_page_zone_module.settings['date_from'], @easy_page_zone_module.settings['date_to'])
      scope = scope.where(["#{EasyCrmCase.table_name}.contract_date >= ?", dates[:from]]) if dates[:from]
      scope = scope.where(["#{EasyCrmCase.table_name}.contract_date <= ?", dates[:to]]) if dates[:to]
    end

    if @easy_page_zone_module.settings['calculate'] == 'count'
      @results = scope.count(:id)
    else
      @results = scope.sum(:price)
    end

    @results[l(:label_none)] = @results.delete(nil).to_i + @results.delete('').to_i if @results[nil] || @results['']


    respond_to do |format|
      format.json
    end
  end

  def user_compare_chart
    settings = @easy_page_zone_module.settings
    @currency = EasySetting.value('user_target_currency')
    @users = User.where(id: settings['users']).sorted

    shift = params[:shift].to_i

    if params[:period].blank?
      period = settings['period'] || 'month'
    else
      period = params[:period].to_s
    end

    date = {}
    case period
    when 'month'
      date[:from] = Date.today.advance(months: shift).beginning_of_month
      date[:to] = Date.today.advance(months: shift).end_of_month
      @title = "#{month_name(date[:from].month)} #{EasySetting.beginning_of_fiscal_year(date[:to]).year}"
    when 'quarter'
      date = EasyUtils::DateUtils.calculate_fiscal_quarter(Date.today + (shift * 3).months)
      @title = "#{month_name(date[:from].month)} - #{month_name(date[:to].month)}  #{date[:to].year}"
    when 'year'
      date[:from] = EasySetting.beginning_of_fiscal_year(Date.today + shift.years)
      date[:to] = EasySetting.end_of_fiscal_year(Date.today + shift.years)
      @title = date[:from].year
    end

    entity_query_params = {}
    entity_query_params['set_filter'] = '1'
    (entity_query_params['easy_currency_code'] = @currency) if @currency
    case settings['data_from']
    when 'crm_case'
      @real_sales = ["#{l(:field_easy_crm_case)} #{EasyCrmCase.human_attribute_name(settings['compare'])}"]
      where_sql =[]
      settings['easy_crm_case_status_state'].each do |state|
        where_sql << "#{state} = :true_value"
      end unless settings['easy_crm_case_status_state'].blank?
      if where_sql.any?
        where_sql = where_sql.join(' OR ')
        @crm_case_statuses_id = EasyCrmCaseStatus.where(where_sql, true_value: true).pluck(:id)
      end

      @compare_entity_query = EasyCrmCaseQuery.new
      entity_query_params['assigned_to_id'] = "=#{ Array(settings[:users]).join('|') }"
      entity_query_params['easy_crm_case_status_id'] = "=#{ Array(@crm_case_statuses_id).join('|') }"
      entity_query_params['group_by'] = ['assigned_to']
      entity_query_params['column_names'] = [settings['compare']]
      entity_query_params['contract_date'] = "#{date[:from]}|#{date[:to]}"
      @compare_entity_query.from_params(entity_query_params)
    when 'invoice'
      @real_sales = ["#{l(:field_easy_invoice)} #{EasyInvoice.human_attribute_name(settings['compare'])}"]
      @compare_entity_query = EasyInvoiceQuery.new
      entity_query_params['author_id'] = "=#{ Array(settings[:users]).join('|') }"
      entity_query_params['easy_invoice_status_id'] = "=#{ Array(settings[:easy_invoice_status_id]).join('|') }"
      entity_query_params['group_by'] = ['author']
      entity_query_params['column_names'] = [settings['compare']]
      entity_query_params['issued_at'] = "#{date[:from]}|#{date[:to]}"
      @compare_entity_query.from_params(entity_query_params)
    end

    @target_query = EasyUserTargetQuery.new
    target_query_params = {}
    target_query_params['user_id'] = "=#{ Array(settings[:users]).join('|') }"
    target_query_params['set_filter'] = '1'
    target_query_params['group_by'] = ['user']
    target_query_params['column_names'] = ['target']
    target_query_params['valid_from'] = "#{date[:from]}|#{date[:to]}"
    @target_query.from_params(target_query_params)

    @targets =[l(:label_chart_target)]
    target_query_groups = @target_query.groups
    compare_query_groups = @compare_entity_query ? @compare_entity_query.groups : []
    @users_name = []
    @users.each do |user|
      @targets << (target_query_groups.include?(user.id) ? target_query_groups[user.id][:sums][:bottom].values.first.round : 0.0)
      @real_sales << (compare_query_groups.include?(user.id) ? compare_query_groups[user.id][:sums][:bottom].values.first.round : 0.0)
      @users_name << user.name
    end

    respond_to do |format|
      format.json
    end
  end

  private

  def find_easy_page_zone_module
    @easy_page_zone_module = EasyPageZoneModule.find(params[:uuid])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project_from_module
    @project = Project.find(@easy_page_zone_module.entity_id) unless @easy_page_zone_module.entity_id.blank?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def easy_crm_charts_authorize
    @project ? authorize : authorize_global
  end

end
