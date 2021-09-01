module EasyMoneyHelper

  include EasyExtensions::EasyAttributeFormatter

  def get_easy_money_projects
    projects = Project.where(Project.allowed_to_condition(User.current, :view_easy_money)).includes(:easy_money_time_entry_expenses).to_a
    ancestor_conditions = projects.collect{|project| "(#{Project.quoted_left_column_name} < #{project.lft} AND #{Project.quoted_right_column_name} > #{project.rgt})"}
    parents = ancestor_conditions.any? ? Project.where(ancestor_conditions.join(' OR ')).includes(:easy_money_time_entry_expenses).to_a : []
    (projects | parents).sort_by(&:lft)
  end

  def time_entry_expenses_columns_per_rate_type(project, time_entry, easy_currency_code)
    html = ''
    project.easy_money_active_rate_types.each do |rate_type|
      html << content_tag(:td, time_entry_expense_per_rate_type(project, time_entry, rate_type.id, easy_currency_code, :format_price => true), :class => 'column')
    end
    html.html_safe
  end

  def price_validation
    easy_money = params[:easy_money]
    return if easy_money.blank?
    easy_money[:vat] = 0.0 unless params[:use_vat]

    if easy_money[:price1] && easy_money[:price2] && ((easy_money[:price1].to_f != 0.0 && easy_money[:price2].to_f == 0.0) || (easy_money[:price1].to_f == 0.0 && easy_money[:price2].to_f != 0.0))
      if params[:use_vat] && params[:use_vat].to_i == 1
        if easy_money[:price1].to_f == 0.0
          easy_money[:price1] = EasyMoneyEntity.compute_price1(@project, easy_money[:price2].to_f)
        elsif easy_money[:price2].to_f == 0.0
          easy_money[:price2] = EasyMoneyEntity.compute_price2(@project, easy_money[:price1].to_f)
        end
      else
        if easy_money[:price1].to_f == 0.0
          easy_money[:price1] = easy_money[:price2]
        elsif easy_money[:price2].to_f == 0.0
          easy_money[:price2] = easy_money[:price1]
        end
      end
    end
  end

  def add_price2
    if params[:easy_money] && !params[:easy_money][:price2]
      params[:easy_money][:vat] = @project.easy_money_settings.vat.to_f
      params[:easy_money][:price2] = EasyMoneyEntity.compute_price2(@project, params[:easy_money][:price1])
    end
  end

  def find_easy_money_project
    entity_id = (params[:easy_money] && params[:easy_money][:entity_id]) || params[:entity_id]
    entity_type = (params[:easy_money] && params[:easy_money][:entity_type]) || params[:entity_type]

    if @easy_money_object
      @entity = @easy_money_object.entity
      @entity_type = @easy_money_object.entity_type
      @entity_id = @easy_money_object.entity_id
      @project = @entity.project
    elsif entity_id.present? && entity_type && EasyMoneyEntity.allowed_entities.include?(entity_type)
      @entity = entity_type.constantize.find(entity_id)
      @entity_type = entity_type
      @entity_id = entity_id
      @project = @entity.project
    elsif entity_type && EasyMoneyEntity.allowed_entities.include?(entity_type) && params[:easy_money] && params[:easy_money][:project_id]
      @project = Project.find(params[:easy_money][:project_id])
      @entity_type = entity_type
    elsif !params[:project_id].blank?
      @project = Project.find(params[:project_id])
      @entity = @project
      @entity_type = 'Project'
      @entity_id = @project.id
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def easy_money_sub_heading(entity = nil)
    entity ||= @entity
    return '' if entity.nil?

    case entity.class.name
    when 'Project'
      (l(:label_project) + ' - ' + h(entity)).html_safe
    when 'Issue'
      (l(:label_issue) + ' - ' + h(entity)).html_safe
    when 'Version'
      (l(:label_version) + ' - ' + h(entity)).html_safe
    end
  end

  def link_to_easy_money_overview(entity = nil)
    entity ||= @entity
    return '' if entity.nil?
    entity_type = entity.class.name
    label = l(:"label_easy_money_sidebar.#{entity_type.underscore}")
    case entity_type
    when 'Project'
      link_to(label, project_easy_money_path(:project_id => entity), :title => label, :class => 'button icon icon-money')
    when 'Issue'
      link_to(label, issue_path(entity), :title => label, :class => 'button icon icon-money')
    when 'Version'
      link_to(label, version_path(entity, :anchor => 'easy_money_version'), :title => label, :class => 'button icon icon-money')
    else
      call_hook(:link_to_easy_money_overview_entity, :entity_type => entity_type, :entity => entity, :project => (@project || entity.project), :label => label)
    end
  end

  def easy_money_time_entries_to_csv(project_entries, issues, easy_money_settings)
    decimal_separator = l(:general_csv_decimal_separator)
    export = Redmine::Export::CSV.generate do |csv|
      headers = []

      headers << l(:field_project)
      headers << l(:field_issue)
      headers << l(:field_spent_on)
      headers << l(:field_user)
      headers << l(:field_activity)
      headers << l(:field_spent_hours)
      headers.concat(EasyMoneyRateType.rate_type_cache.map(&:translated_name))

      csv << headers

      project_entries.each do |time_entry|
        fields = []

        fields << time_entry.project.name
        fields << 'N/A'
        fields << format_date(time_entry.spent_on)
        fields << time_entry.user.name
        fields << time_entry.activity.name
        fields << time_entry.hours.to_s.gsub('.', decimal_separator)

        EasyMoneyRateType.rate_type_cache.each do |rate_type|
          fields << time_entry_expense_per_rate_type(time_entry.project, time_entry, rate_type.id, time_entry.project.easy_currency_code, :format_price => false).to_s.gsub('.', decimal_separator)
        end

        csv << fields
      end

      issues.each do |issue|
        issue.time_entries.each do |time_entry|
          fields = []

          fields << issue.project.name
          fields << issue.subject
          fields << format_date(time_entry.spent_on)
          fields << time_entry.user.name
          fields << time_entry.activity.name
          fields << time_entry.hours.to_s.gsub('.', decimal_separator)

          EasyMoneyRateType.rate_type_cache.each do |rate_type|
            fields << time_entry_expense_per_rate_type(issue.project, time_entry, rate_type.id, issue.project.easy_currency_code, :format_price => false).to_s.gsub('.', decimal_separator)
          end

          csv << fields
        end
      end
    end
    export
  end

  def render_api_easy_money_entity(api, easy_money_entity)
    api.__send__(easy_money_entity.class.name.underscore.to_sym) {
      api.id(easy_money_entity.id)
      api.entity_type(easy_money_entity.entity_type)
      api.entity_id(easy_money_entity.entity_id)
      api.price1(easy_money_entity.price1)
      api.price2(easy_money_entity.price2) if easy_money_entity.respond_to?(:price2)
      api.easy_currency_code(easy_money_entity.easy_currency_code)
      api.vat(easy_money_entity.vat) if easy_money_entity.respond_to?(:vat)
      api.spent_on(easy_money_entity.spent_on)
      api.description(easy_money_entity.description)
      api.name(easy_money_entity.name)
      api.version_id(easy_money_entity.version_id)
      api.user_id(easy_money_entity.user_id) if easy_money_entity.respond_to?(:user_id)
      api.metric_units(easy_money_entity.metric_units) if easy_money_entity.respond_to?(:metric_units)
      api.price_per_unit(easy_money_entity.price_per_unit) if easy_money_entity.respond_to?(:price_per_unit)
      api.easy_external_id(easy_money_entity.easy_external_id) if easy_money_entity.respond_to?(:easy_external_id)

      render_api_custom_values(easy_money_entity.visible_custom_field_values, api)
    }
  end

  def render_api_easy_money_entities(api, easy_money_entities, entity_count, offset, limit, klass)
    api.array klass, api_meta(:total_count => entity_count, :offset => offset, :limit => limit) do
      easy_money_entities.each do |easy_money_entity|
        render_api_easy_money_entity(api, easy_money_entity)
      end
    end
  end

  def render_api_easy_money_rate_priorities(api, project)
    api.easy_money_rate_priorities do
      EasyMoneyRateType.rate_type_cache.each do |rate_type|
        api.easy_money_rate_type do
          api.id(rate_type.id)
          api.name(rate_type.translated_name)
          EasyMoneyRatePriority.rate_priorities_by_rate_type_and_project(rate_type.id, project.try(:id)).each do |rate_priority|
            api.easy_money_rate_priority do
              api.id(rate_priority.id)
              api.entity(l("easy_money_entity.#{rate_priority.entity_type.underscore}"))
              api.position(rate_priority.position)
            end
          end
        end
      end
    end
  end

  def load_current_easy_currency_code
    @current_easy_currency_code = EasyCurrency[params[:easy_currency_code]].try(:iso_code) if params[:easy_currency_code].present?
    @current_easy_currency_code ||= @project.easy_currency_code
    @current_easy_currency_code ||= EasyCurrency.default_code
  end

  def format_easy_money_rate(easy_money_rate, project)
    html = format_easy_money_price easy_money_rate.unit_rate, project, easy_money_rate.easy_currency_code, round: false, precision: 2

    if easy_money_rate.easy_currency_code && project.try(:easy_currency_code) && easy_money_rate.easy_currency_code != project.easy_currency_code
      html << " ("
      html << format_easy_money_price(easy_money_rate.unit_rate(project.easy_currency_code), project, round: false, precision: 2)
      html << ")"
    end

    html.html_safe
  end

  private

  # Return n non-breaking spaces.
  def nbsp(n)
    ('&nbsp;' * n).html_safe
  end

  def time_entry_expense_per_rate_type(project, time_entry, rate_type_id, easy_currency_code, options = {})
    time_entry.easy_money_time_entry_expenses.each do |time_entry_expense|
      if time_entry_expense.rate_type_id == rate_type_id
        price = time_entry_expense.price(easy_currency_code)

        return options[:format_price] ? format_easy_money_price(price, project, easy_currency_code) : price
      end
    end

    'N/A'
  end

end
