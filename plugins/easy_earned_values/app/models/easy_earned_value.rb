class EasyEarnedValue < ActiveRecord::Base
  include Redmine::SafeAttributes

  # Project has usualy some delay
  # This value represent how much will be project duration expanded
  RELATIVE_DUE_DATE_DELAY = 0.2

  # Baseline could be a baseline or a regular project
  belongs_to :baseline, class_name: 'Project', foreign_key: 'baseline_id'
  belongs_to :project
  has_many :data, dependent: :destroy, class_name: 'EasyEarnedValueData', foreign_key: 'easy_earned_value_id'

  validates :project, :baseline, :name, :type, presence: true

  safe_attributes 'project_id', 'baseline_id', 'name', 'type', 'project_default', 'reload_constantly'

  before_validation :check_or_set_baseline
  before_save :check_project_default

  scope :for_reloading, lambda {
    eager_load(:project).preload(:data).where(projects: { status: Project::STATUS_ACTIVE })
  }

  def type_name
    self.class.type_name
  end

  def data_type
    self.class.data_type
  end

  def reload_all
    raise NotImplementedError
  end

  def reload_actual
    raise NotImplementedError
  end

  def other_values
    # Get last data containing every values
    last_values = data.order(:date).reverse_order.where.not(ac: nil, ev: nil, pv: nil).first

    unless last_values
      return {}
    end

    {
      date: last_values.date,
      sv: last_values.ev - last_values.pv,
      spi: last_values.ev / last_values.pv,
      cv: last_values.ev - last_values.ac,
      cpi: last_values.ev / last_values.ac
    }
  end

  private

    def check_or_set_baseline
      self.baseline_id ||= project_id
    end

    def check_project_default
      if project_default? && project_default_changed?
        EasyEarnedValue.where(project_id: project_id).update_all(project_default: false)
      end
    end

    def load_dates_from_baseline
      project_ids = baseline.self_and_descendants.pluck(:id)
      dates = Issue.where(project_id: project_ids).pluck(:start_date, :due_date)
      dates.flatten!
      dates.compact!

      self.start_date, self.due_date = dates.minmax
      update_columns(start_date: start_date, due_date: due_date)
    end

end

class EasyEarnedValue::EstimatedHours < EasyEarnedValue

  def self.type_name
    I18n.t('easy_earned_values.types.estimated_hours.name')
  end

  def self.data_type
    'estimated_hours'
  end

  def reload_all
    if !baseline
      return
    end

    load_dates_from_baseline

    if start_date.nil? || due_date.nil?
      return
    end

    data_to_save = calculate_planned_data

    EasyEarnedValue.transaction do
      data.delete_all
      update_column(:actual_reloaded_at, nil)
      EasyEarnedValueData.import(data_to_save.values) if data_to_save
    end

    # Just in case
    data.reload

    reload_actual

    update_column(:data_initilized, true)
  end

  def due_date_with_delay
    return @due_date_with_delay if defined?(@due_date_with_delay)

    if start_date && due_date
      @due_date_with_delay ||= due_date + (due_date - start_date) * RELATIVE_DUE_DATE_DELAY
    end
  end

  def calculate_planned_data
    date_changes = Hash.new { |hash, key| hash[key] = 0 }

    project_ids = baseline.self_and_descendants.pluck(:id)
    issues = Issue.where(project_id: project_ids).
                   where.not(estimated_hours: nil).
                   pluck(:start_date, :due_date, :estimated_hours)

    if issues.empty?
      return
    end

    issues.each do |issue_start_date, issue_due_date, issue_estimated_hours|
      if !issue_start_date
        issue_start_date = start_date
      end

      if !issue_due_date
        issue_due_date = due_date
      end

      # EV's dates are calculated from these issues
      # so there is no need to check `issue_start_date < start_date`

      duration = (issue_due_date - issue_start_date).to_f

      # If dates are equal - duration is 0 but for this formula is desirable 1
      estimated_per_day = issue_estimated_hours.to_f / (duration + 1)

      issue_start_date.upto(issue_due_date).each do |date|
        date_changes[date] += estimated_per_day
      end
    end

    planned_values = {}
    value = 0

    data_to_save = Hash.new do |hash, date|
      hash[date] = data.build(date: date, pv: 0)
    end

    # Calculate cumulative sum
    start_date.upto(due_date_with_delay).each do |date|
      value += date_changes[date]
      data_to_save[date].pv += value
    end

    data_to_save
  end

  def reload_actual
    self.actual_reloaded_at ||= start_date

    actual_data = Hash.new { |hash, date| hash[date] = { all_evs: [] } }

    project_ids = project.self_and_descendants.pluck(:id)
    issues = Issue.where(project_id: project_ids).preload(journals: :details)

    issues.each do |issue|
      min_date = [issue.created_on.to_date, issue.start_date].compact.min
      estimated_hours = issue.estimated_hours.to_f
      done_ratio = issue.done_ratio.to_f

      # We have to move from present to past (reverse order)
      Date.today.downto(actual_reloaded_at).each do |date|

        # If issue didn't exist that time -> should not be taken into account
        # A problem could be an import
        #   - an issue exists on external system
        #   - but an exporter have set current date
        if date < min_date
          break
        end

        actual_data[date][:all_evs] << (estimated_hours * done_ratio / 100)

        # In one day, there could be more records
        journals = issue.journals.select {|j| j.created_on.to_date == date }

        # First change win because it stores data from yesterday
        details = journals.flat_map(&:details).sort_by(&:id)

        estimated_hours_detail = details.find {|d| d.prop_key == 'estimated_hours' }
        done_ratio_detail = details.find {|d| d.prop_key == 'done_ratio' }

        if estimated_hours_detail
          estimated_hours = estimated_hours_detail.old_value.to_f
        end

        if done_ratio_detail
          done_ratio = done_ratio_detail.old_value.to_f
        end
      end
    end

    ac_scope = TimeEntry.where(issue_id: issues.ids)

    # time entry changed or created after actual_reloaded_at date for a date before actual_reloaded_at date
    first_inconsistent_time_entry_date = ac_scope.where('spent_on < ? AND updated_on >= ?', actual_reloaded_at, actual_reloaded_at).pluck(:spent_on).min
    # TimeEntry.select('MIN(spent_on) AS "spent_on"').where('spent_on < ? AND updated_on > ?', *(2 * [actual_reloaded_at])).distinct.pluck(:spent_on).first

    first_inconsistent_time_entry_date ||= actual_reloaded_at

    ac = ac_scope.where('spent_on < ?', first_inconsistent_time_entry_date).sum(:hours)
    all_time_entries = ac_scope.where('spent_on >= ?', first_inconsistent_time_entry_date).
                                group(:spent_on).
                                sum(:hours)

    # EV is not cumulative
    # Its already calculated for specific date
    first_inconsistent_time_entry_date.upto(Date.today).each do |date|
      if date > Date.today
        break
      end

      ev = actual_data[date][:all_evs].sum if date >= actual_reloaded_at
      ac += (all_time_entries[date] || 0)

      data_item = data.find{|i| i.date == date }

      if data_item
        new_values = { ev: ev, ac: ac }.compact
        data_item.update_columns(**new_values)
      else
        # This shoudl never happend because data must exist from planned reloading
      end
    end

    update_column(:actual_reloaded_at, Date.today)
  end

end
