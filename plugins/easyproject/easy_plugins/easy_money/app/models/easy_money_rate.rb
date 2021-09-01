class EasyMoneyRate < ActiveRecord::Base
  self.table_name = 'easy_money_rates'

  belongs_to :project
  belongs_to :rate_type, class_name: 'EasyMoneyRateType'
  belongs_to :entity, :polymorphic => true
  belongs_to :easy_currency, foreign_key: :easy_currency_code, primary_key: :iso_code

  validates :entity_id, uniqueness: { scope: [:entity_type, :rate_type_id, :project_id] }
  validates :unit_rate, presence: true, numericality: {greater_than_or_equal_to: 0}, allow_blank: true


  scope :easy_money_rate_by_project_by_rate_by_entity, lambda {|project, rate, entity_type, entity_id| where("#{EasyMoneyRate.table_name}.project_id = #{project.id} AND #{EasyMoneyRate.table_name}.rate_type_id = #{rate.id} AND #{EasyMoneyRate.table_name}.entity_type = '#{entity_type}' AND #{EasyMoneyRate.table_name}.entity_id = #{entity_id}") }

  scope :with_easy_money_setting, -> setting_name {
    easy_money_rate_table = EasyMoneyRate.arel_table
    easy_money_settings_table = EasyMoneySettings.arel_table

    join_table = easy_money_rate_table.join(easy_money_settings_table).
        on(
            easy_money_rate_table[:entity_id].eq(easy_money_settings_table[:id]).
                and(easy_money_rate_table[:entity_type].eq 'EasyMoneySettings').
                and(easy_money_settings_table[:name].eq setting_name)
        ).join_sources

    joins(join_table)
  }

  class << self
    def find_rate(rate_type_id, entity_type, entity_id, project_id)
      project_id = [project_id, nil].uniq

      where(rate_type_id: rate_type_id, entity_type: entity_type, entity_id: entity_id, project_id: project_id).order(project_id: :desc).first
    end

    def get_unit_rate(rate_type, entity_type, entity_id, project_id = nil, valid_to = nil, easy_currency_code = nil)
      easy_currency_code ||= project_id && Project.find_by(id: project_id)&.easy_currency_code
      easy_currency_code ||= EasyCurrency.default_code

      easy_money_rate = find_rate(rate_type, entity_type, entity_id, project_id)

      easy_money_rate.try(:unit_rate, easy_currency_code, valid_to)
    end

    def find_rate_for_setting(setting_name, project_id)
      project_id = [project_id, nil].uniq
      with_easy_money_setting(setting_name).where(project_id: project_id).order(project_id: :desc).first
    end

    def get_unit_rate_for_issue(issue, rate_type, easy_currency_code)
      get_unit_rate_for_entity_in_currency(issue, rate_type, issue.project_id, easy_currency_code)
    end

    def get_unit_rate_for_entity_in_currency(entity, rate_type, project_id = nil, easy_currency_code = nil, valid_to = nil)
      unit_rate = nil

      EasyMoneyRatePriority.rate_priorities_by_rate_type_and_project(rate_type, project_id).pluck(:entity_type).each do |rate_priority_entity_type|
        break unless unit_rate.nil?

        entity_type = case rate_priority_entity_type
                        when 'TimeEntryActivity'
                          'Enumeration'
                        when 'User'
                          'Principal'
                        else
                          'Role'
                      end

        entity_id = get_easy_money_rate_entity_id_for_entity(entity, rate_priority_entity_type)
        next if entity_id.nil?

        unit_rate = EasyMoneyRate.get_unit_rate(rate_type, entity_type, entity_id, project_id, valid_to, easy_currency_code)
      end

      unit_rate.to_f
    end
  end

  # Return the EasyMoneyRate record based on params
  def self.get_rate(rate_type, entity_type, entity_id, project_id = nil, valid_from = nil, valid_to = nil)
    scope = get_rate_scope(rate_type, entity_type, entity_id, project_id, valid_from, valid_to)
    scope.first if scope
  end

  # Return the EasyMoneyRate scope based on params
  def self.get_rate_scope(rate_type, entity_type, entity_id, project_id = nil, valid_from = nil, valid_to = nil)
    return nil if entity_type.blank? || entity_id.blank?
    scope = EasyMoneyRate.where(:rate_type_id => rate_type, :entity_type => entity_type.to_s, :entity_id => entity_id, :project_id => project_id)

    #    cond << ["#{EasyMoneyRate.table_name}.valid_from <= ? OR #{EasyMoneyRate.table_name}.valid_from IS NULL", valid_from.to_date] unless valid_from.nil?
    #    cond << ["#{EasyMoneyRate.table_name}.valid_to >= ? OR #{EasyMoneyRate.table_name}.valid_to IS NULL", valid_to.to_date] unless valid_to.nil?

    scope
  end

  def self.affected_projects(type, tab, project_id)
    scope = Project.active.non_templates.has_module(:easy_money)
    case type
    when 'global'
      case tab
      when'EasyMoneyRateUser'
        affected_projects = scope.where.not(EasyMoneyRate.where("project_id = projects.id AND entity_type = 'Principal' ").arel.exists).sorted
      when 'EasyMoneyRateTimeEntryActivity'
        affected_projects = scope.where.not(EasyMoneyRate.where("project_id = projects.id AND entity_type = 'Enumeration' ").arel.exists).sorted
      when 'EasyMoneyRateRole'
        affected_projects = scope.where.not(EasyMoneyRate.where("project_id = projects.id AND entity_type = 'Role' ").arel.exists).sorted
      when 'EasyMoneyOtherSettings'
        affected_projects = scope.includes(:easy_money_settings_assoc).where(easy_money_settings: {project_id: nil}).sorted
      end
    when 'all'
      affected_projects = scope.sorted
    when 'self'
      affected_projects = Project.where(id: project_id)
    when 'self_and_descendants'
      project = Project.find_by(id: project_id)
     affected_projects = project.self_and_descendants.active.non_templates.has_module(:easy_money).sorted if project
    end
    affected_projects || Project.none
  end

  def self.copy_to(project_from, project_to)
    EasyMoneyRate.where(:project_id => project_from.id).all.each do |project_from_rate|
      rate = project_from_rate.dup
      rate.project_id = project_to.id
      rate.save
    end
  end

  def self.get_easy_money_rate_by_project(project, fallback_to_global = true)
    project_id = project.is_a?(Project) ? project.id : project

    emr = EasyMoneyRate.where(["#{EasyMoneyRate.table_name}.project_id = ?", project_id]).all
    emr = EasyMoneyRate.where("#{EasyMoneyRate.table_name}.project_id IS NULL").all if emr.blank? && fallback_to_global
    emr
  end

  def self.get_easy_money_rate_by_project_and_entity_type(project, entity_type, fallback_to_global = true)
    project_id = project.is_a?(Project) ? project.id : project

    emr = EasyMoneyRate.where(["#{EasyMoneyRate.table_name}.project_id = ?", project_id]).where(["#{EasyMoneyRate.table_name}.entity_type = ?", entity_type]).all
    emr = EasyMoneyRate.where("#{EasyMoneyRate.table_name}.project_id IS NULL").where(["#{EasyMoneyRate.table_name}.entity_type = ?", entity_type]).all if emr.blank? && fallback_to_global
    emr
  end

  # Return a concrete unit_rate based on rate priorities for a time entry
  def self.get_unit_rate_for_time_entry(time_entry, rate_type)
    get_unit_rate_for_entity_in_currency(time_entry, rate_type, time_entry.project_id, nil, time_entry.spent_on)
  end

  # Return a concrete unit_rate based on rate priorities for a issue
  # def self.get_unit_rate_for_issue(issue, rate_type)
  #   get_unit_rate_for_entity(issue, rate_type, issue.project_id, nil, nil)
  # end

  def self.get_easy_money_rate_entity_id_for_entity(entity, easy_money_rate_entity_type)
    case entity.class.name
    when 'TimeEntry'
      get_easy_money_rate_entity_id_for_time_entry(entity, easy_money_rate_entity_type)
    when 'Issue'
      get_easy_money_rate_entity_id_for_issue(entity, easy_money_rate_entity_type)
    else
      nil
    end
  end

  def self.get_easy_money_rate_entity_id_for_time_entry(time_entry, easy_money_rate_entity_type)
    case easy_money_rate_entity_type
    when 'Role'
      role = time_entry.user.roles_for_project(time_entry.project).min_by(&:position)
      role && role.id
    when 'TimeEntryActivity'
      time_entry.activity_id
    when 'User'
      time_entry.user_id
    end
  end

  def self.get_easy_money_rate_entity_id_for_issue(issue, easy_money_rate_entity_type)
    case easy_money_rate_entity_type
    when 'Role'
      role = issue.assigned_to.roles_for_project(issue.project).min_by(&:position) if issue.assigned_to && issue.assigned_to.is_a?(User)
      role && role.id
    when 'TimeEntryActivity'
      issue.activity_id
    when 'User'
      issue.assigned_to_id
    end
  end

  def unit_rate(to_easy_currency_code = easy_currency_code, exchange_date = nil)
    original_unit_rate = read_attribute(:unit_rate)
    exchange_date ||= Date.current

    EasyCurrencyExchangeRate.recalculate(easy_currency_code, to_easy_currency_code, original_unit_rate, exchange_date)
  end

end
