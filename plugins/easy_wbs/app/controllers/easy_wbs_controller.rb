class EasyWbsController < ApplicationController
  accept_api_auth :index, :budget
  menu_item :easy_wbs

  before_action :check_rest_api_enabled, only: [:index]
  before_action :find_project_by_project_id, if: proc { params[:project_id].present? }
  before_action :check_easy_money, only: [:budget, :budget_overview, :budget_links]
  before_action :authorize, if: proc { @project.present? }
  before_action :authorize_global, if: proc { @project.nil? }

  helper :easy_mindmup
  helper :custom_fields

  include_query_helpers

  def index
    retrieve_query

    respond_to do |format|
      format.html { render(layout: !request.xhr?) }
      format.api do
        load_issues
        load_projects
        load_trackers
        load_users
        load_versions
        load_relations
      end
    end
  end

  def budget
    result = {
      issues: budget_data_for(Issue, params[:issue_ids], only_self: params[:non_cumulative_tasks] == '1'),
      projects: budget_data_for(Project, params[:project_ids])
    }

    render json: result
  end

  def budget_overview
    #
    # Issue
    #
    if params[:entity_type] == 'Issue' && params[:entity_id].present?
      @budget_entity = Issue.visible.preload(:project).find_by(id: params[:entity_id])
      @budget_project = @budget_entity&.project

      if @budget_entity.nil? || @budget_project.nil?
        return render_404
      end

      unless @budget_project.easy_money_settings&.use_easy_money_for_issues?
        return render partial: 'easy_money/warning_not_allowed_for_tasks'
      end

    #
    # Project
    #
    elsif params[:entity_type] == 'Project' && params[:entity_id].present?
      @budget_entity = @budget_project = Project.visible.find_by(id: params[:entity_id])

      if @budget_entity.nil?
        return render_404
      end

    #
    # Something else
    #
    else
      return render_404
    end

    unless User.current.allowed_to?(:view_easy_money, @budget_project) && @budget_entity.easy_money_visible?
      return render_403
    end

    render_options = { layout: false }
    tab_name = params[:tab]
    if tab_name == 'overview'
      render_options[:partial] = 'easy_money/entity_overview'
      render_options[:locals] = { project: @budget_project,
                                  entity: @budget_entity,
                                  easy_currency_code: (params[:currency].presence || @budget_project.easy_currency_code) }
    elsif %w(other_revenue expected_revenue other_expense expected_expense travel_cost travel_expense).include? tab_name
      money_params = { entity_type: params[:entity_type], entity_id: params[:entity_id], spent_on: Date.today, easy_currency_code: params[:currency].presence }
      money_class = 'easy_money_' + tab_name
      render_options[:template] = 'easy_money_' + tab_name + 's/new'
      @easy_money_object = money_class.classify.constantize.new(money_params)
    else
      return render_404
    end

    respond_to do |format|
      format.html { render render_options }
    end
  end

  def budget_links
    case params[:entity_type]
    when 'Project'
      @entity = Project.visible.find_by(id: params[:entity_id])
      @entity_project = @entity
    when 'Issue'
      @entity = Issue.visible.preload(:project).find_by(id: params[:entity_id])
      @entity_project = @entity&.project
    end

    if @entity.nil?
      return render_404
    else
      links = [{ label: I18n.t(:label_easy_money_overview), tab: 'overview' }]
      easy_money_settings = @entity_project.easy_money_settings

      if easy_money_settings && easy_money_settings.revenues_type == 'list'
        if User.current.allowed_to?(:easy_money_manage_other_revenue, @entity_project)
          links << { label: I18n.t(:label_easy_money_new_revenue_text_new), tab: 'other_revenue' }

        elsif User.current.allowed_to?(:easy_money_manage_expected_revenue, @entity_project) && easy_money_settings.show_expected?
          links << { label: I18n.t(:label_easy_money_new_revenue_text_new), tab: 'expected_revenue' }
        end
      end

      if easy_money_settings && easy_money_settings.expenses_type == 'list'
        if User.current.allowed_to?(:easy_money_manage_other_expense, @entity_project)
          links << { label: I18n.t(:label_easy_money_new_expense_text_new), tab: 'other_expense' }

        elsif User.current.allowed_to?(:easy_money_manage_expected_expense, @entity_project) && easy_money_settings.show_expected?
          links << { label: I18n.t(:label_easy_money_new_expense_text_new), tab: 'expected_expense' }
        end
      end

      render json: links
    end
  end

  private

    def check_easy_money
      if !EasyWbs.easy_money?(@project)
        return render_404
      end
    end

    def check_rest_api_enabled
      if Setting.rest_api_enabled != '1'
        render_error message: l('easy_mindmup.errors.no_rest_api')
        return false
      end
    end

    def query_class
      easy_extensions? ? EasyWbsEasyIssueQuery : EasyWbs::IssueQuery
    end

    def retrieve_query
      if params[:query_id].present?
        cond  = 'project_id IS NULL'

        if @project
          cond << " OR project_id = #{@project.id}"

          # In Easy Project query can be defined for subprojects
          if !@project.root? && EasyWbs.easy_extensions?
            ancestors = @project.ancestors.select(:id).to_sql
            cond << " OR (is_for_subprojects = #{Project.connection.quoted_true} AND project_id IN (#{ancestors}))"
          end
        end

        @query = query_class.where(cond).find_by(id: params[:query_id])
        raise ActiveRecord::RecordNotFound if @query.nil?
        raise Unauthorized unless @query.visible?

        @query.project = @project
        sort_clear
      else
        @query = query_class.new(name: '_')
        @query.project = @project
        @query.from_params(params)
      end
    end

    def load_issues
      @issues = @query.entities(order: "#{Issue.table_name}.id")
      @issue_ids = @issues.map(&:id)

      if @issues.blank?
        return
      end

      # All ancestors conditions
      tree_conditions = []
      @issues.each do |issue|
        tree_conditions << "(root_id = #{issue.root_id} AND lft < #{issue.lft} AND rgt > #{issue.rgt})"
      end
      tree_conditions = tree_conditions.join(' OR ')

      @missing_parent_issues = Issue.where(tree_conditions).where.not(id: @issue_ids)
    end

    def load_projects
      @projects = @project.self_and_descendants.where.not(status: [Project::STATUS_CLOSED, Project::STATUS_ARCHIVED])
    end

    def load_trackers
      @trackers = Setting.display_subprojects_issues? ? @project.rolled_up_trackers : @project.trackers
    end

    def load_users
      @users = @project.assignable_users_including_all_subprojects
    end

    def load_versions
      @versions = @projects.flat_map(&:shared_versions).select(&:open?).uniq
    end

    def load_relations
      @relations = IssueRelation.where(issue_from_id: @issue_ids, issue_to_id: @issue_ids)
    end

  def budget_data_for(entity_klass, entity_ids, options = {})
    budget_data = {}
    entity_klass.visible.where(id: entity_ids).each do |entity|
      budget_data[entity.id] = collect_money_data(entity, options)
    end
    budget_data
  end

  def collect_money_data(entity, options = {})
    entity_id_key = (entity.class.name.underscore + '_id').to_sym
    data = { entity_id_key => entity.id } # TODO: use entity_id: entity.id ????

    if (easy_money = entity.easy_money(params[:currency]))
      only_self = options[:only_self]

      if params[:with_real_profit] == '1'
        # `only_self` and `without_descendants` do the same thing
        # However it's easy_money so we must be careful what we are doing
        data[:real_profit] = easy_money.other_profit(nil, nil, only_self: only_self, without_descendants: only_self)
      end

      if params[:with_planned_profit] == '1'
        data[:planned_profit] = easy_money.expected_profit(nil, only_self: only_self)
      end

      if params[:with_planned_revenue] == '1'
        data[:planned_revenue] = easy_money.sum_expected_revenues(nil, only_self: only_self)
      end

      if params[:with_real_revenue] == '1'
        data[:real_revenue] = easy_money.sum_other_revenues(nil, only_self: only_self)
      end

      if params[:with_costs] == '1'
        data[:planned_costs], data[:real_costs] = easy_money.sum_planned_and_other_expenses(only_self: only_self)
      end
    end

    data
  end

end
