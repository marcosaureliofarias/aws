class EasyGanttProController < EasyGanttController
  accept_api_auth :lowest_progress_tasks, :cashflow_data

  before_action :require_admin, only: [:recalculate_fixed_delay]

  # TODO: Calculate progress date on DB
  def lowest_progress_tasks
    project_ids = Array(params[:project_ids])

    @data = Hash.new { |hash, key| hash[key] = { date: Date.new(9999), ids: [] } }

    issues = Issue.open.joins(:status).
                   where(project_id: project_ids).
                   where.not(start_date: nil, due_date: nil).
                   pluck(:project_id, :id, :start_date, :due_date, :done_ratio)

    issues.each do |p_id, i_id, start_date, due_date, done_ratio|
      diff = due_date - start_date
      add_days = (diff * done_ratio.to_i) / 100
      progress_date = start_date + add_days.days

      project_data = @data[p_id]
      if project_data[:date] == progress_date
        project_data[:ids] << i_id
      elsif project_data[:date] > progress_date
        project_data[:date] = progress_date
        project_data[:ids] = [i_id]
      end
    end

    ids = @data.flat_map{|_, data| data[:ids]}
    @issues = Issue.select(:project_id, :id, :subject).where(id: ids)
  end

  def cashflow_data
    unless EasyGantt.easy_money?
      return render_404
    end

    @data = {}
    tree_conditions = []

    @base_projects = Project.where(id: params[:project_ids]).pluck(:id, :lft, :rgt)
    @base_projects.each do |id, lft, rgt|

      tree_conditions << "(projects.lft >= #{lft} AND projects.rgt <= #{rgt})"
    end

    tree_conditions = tree_conditions.join(' OR ')

    if params[:include_planned] == '1'
      revenues = Project.joins('INNER JOIN easy_money_expected_revenues m ON projects.id = m.project_id').
                         where(tree_conditions).
                         group('m.spent_on', 'projects.id').
                         pluck('projects.lft', 'projects.rgt', 'm.spent_on', 'SUM(m.price1)');
      cashflow_data_add(:planned_revenues, revenues)


      expenses = Project.joins('INNER JOIN easy_money_expected_expenses m ON projects.id = m.project_id').
                         where(tree_conditions).
                         group('m.spent_on', 'projects.id').
                         pluck('projects.lft', 'projects.rgt', 'm.spent_on', 'SUM(m.price1)');
      cashflow_data_add(:planned_expenses, expenses)
    end

    if params[:include_real] == '1'
      revenues = Project.joins('INNER JOIN easy_money_other_revenues m ON projects.id = m.project_id').
                         where(tree_conditions).
                         group('m.spent_on', 'projects.id').
                         pluck('projects.lft', 'projects.rgt', 'm.spent_on', 'SUM(m.price1)');
      cashflow_data_add(:real_revenues, revenues)


      expenses = Project.joins('INNER JOIN easy_money_other_expenses m ON projects.id = m.project_id').
                         where(tree_conditions).
                         group('m.spent_on', 'projects.id').
                         pluck('projects.lft', 'projects.rgt', 'm.spent_on', 'SUM(m.price1)');
      cashflow_data_add(:real_expenses, expenses)
    end

    if params[:include_time_entry_expenses] == '1'
      expenses = Project.joins('INNER JOIN time_entries t ON projects.id = t.project_id',
                               'INNER JOIN easy_money_time_entries_expenses m ON t.id = m.time_entry_id').
                         where(tree_conditions).
                         group('t.spent_on', 'projects.id').
                         pluck('projects.lft', 'projects.rgt', 't.spent_on', 'SUM(m.price)')
      cashflow_data_add(:time_entry_expenses, expenses)
    end

    respond_to do |format|
      format.json { render json: @data }
    end
  end

  def recalculate_fixed_delay
    statuses = [Project::STATUS_ACTIVE]
    if EasyGantt.easy_extensions?
      statuses << Project::STATUS_PLANNED
    end

    issues = Issue.joins(:project).where(projects: { status: statuses })
    relations = IssueRelation.preload(:issue_from, :issue_to).
                              where(relation_type: IssueRelation::TYPE_PRECEDES).
                              where(issue_from_id: issues, issue_to_id: issues).
                              where.not(delay: nil)

    relations.each do |relation|
      next if relation.issue_from.nil? || relation.issue_to.nil?

      from = relation.issue_from.due_date || relation.issue_from.start_date
      to = relation.issue_to.start_date || relation.issue_to.due_date

      next if from.nil? || to.nil?

      saved_delay = relation.delay
      correct_delay = (to-from-1).to_i

      if saved_delay != correct_delay
        relation.update_column(:delay, correct_delay)
      end
    end

    flash[:notice] = l(:notice_easy_gantt_fixed_delay_recalculated)
    redirect_to :back
  end

  private

    def cashflow_data_add(data_key, data)
      data.each do |lft, rgt, spent_on, price|
        @base_projects.each do |bid, blft, brgt|
          if lft >= blft && rgt <= brgt
            @data[bid] ||= {}
            @data[bid][data_key] ||= {}
            tmp_data = @data[bid][data_key]
            tmp_data[spent_on] ||= 0
            tmp_data[spent_on] += price
          end
        end
      end
    end

end
