class EasyGanttResource < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :issue
  belongs_to :user

  validates :date, :issue_id, :hours, presence: true
  validates :date, uniqueness: { scope: [:issue_id, :user_id, :start], message: :allocation_exists }

  validates_numericality_of :hours, less_than: 99_999

  scope :between_dates, lambda { |start_date, end_date|
    where('date BETWEEN ? AND ?', start_date, end_date) if start_date && end_date
  }
  scope :active_and_planned, lambda {
    statuses = [Project::STATUS_ACTIVE]

    if Project.const_defined?(:STATUS_PLANNED)
      statuses << Project::STATUS_PLANNED
    end

    joins(issue: :project).where(projects: { status: statuses })
  }

  scope :non_templates, lambda {
    joins(issue: :project).where(projects: { easy_is_easy_template: false })
  }

  safe_attributes 'custom', 'date', 'hours', 'issue_id', 'user_id', 'start'

  def self.hours_per_day(user=nil)
    ActiveSupport::Deprecation.warn('EasyGanttResource.hours_per_day is deprecated. Use EasyGanttResource.hours_on_week instead.')

    default_hours = EasySetting.value(:easy_gantt_resources_hours_per_day).to_f
    return default_hours if user.nil?

    user = ((user.is_a?(User) || user.is_a?(Group)) ? user.id : user).to_s
    users_hours = EasySetting.value(:easy_gantt_resources_users_hours_limits)

    (users_hours[user].presence || default_hours).to_f
  end

  def self.hours_on_week(user=nil)
    user = user.id if user.is_a?(Principal)
    user = user.to_s

    result = []

    # Advance definition - hours per cwday
    if EasySetting.value(:easy_gantt_resources_advance_hours_definition)
      default_hours = EasySetting.value(:easy_gantt_resources_advance_hours_per_days)
      users_hours = EasySetting.value(:easy_gantt_resources_users_advance_hours_limits)
      user_hours = Array(users_hours[user])

      7.times do |i|
        result << (user_hours[i].presence || default_hours[i]).to_f
      end
    else
      default_hours = EasySetting.value(:easy_gantt_resources_hours_per_day)
      users_hours = EasySetting.value(:easy_gantt_resources_users_hours_limits)
      hours = (users_hours[user].presence || default_hours).to_f

      weekends = EasyGantt.non_working_week_days(user)

      7.times do |i|
        # Weekends are in 1..7
        if weekends.include?(i+1)
          result << 0
        else
          result << hours
        end
      end
    end

    result
  end

  def self.estimated_ratio(user=nil)
    user = user.id if user.is_a?(User) || user.is_a?(Group)
    user = user.to_s

    ratios = EasySetting.value(:easy_gantt_resources_users_estimated_ratios)

    (ratios[user].presence || 1).to_f
  end

  # Save new issue allocations
  # Old allocations will be deleted
  #
  # TODO: Use transaction - save everything or nothing
  #
  def self.save_allocation_from_params(params, default_custom: false)
    saved_resources = {}
    unsaved_resources = {}

    params.each do |issue, resources|
      saved_resources[issue] = []
      unsaved_resources[issue] = []

      error_reasons = []
      error_reasons.concat(issue.allocable_errors)
      error_reasons.concat(issue.resources_editable_errors)

      if error_reasons.any?
        reason = error_reasons.join(', ')
        unless resources.nil?
          resources.each { |r| r['reason'] = reason }

          unsaved_resources[issue].concat(resources)
        end
        next
      end

      # Allocations are replaced
      issue.easy_gantt_resources.delete_all

      resources.each do |resource|
        custom = resource.has_key?('custom') ? resource['custom'] : default_custom

        date = resource['date'].to_date rescue nil
        easy_gantt_resource = issue.easy_gantt_resources.build(
          user_id: issue.assigned_to_id,
          date: date,
          hours: resource['hours'].to_f,
          custom: custom,
          start: resource['start'])

        if easy_gantt_resource.save
          saved_resources[issue] << resource
        else
          resource['reason'] = easy_gantt_resource.errors.full_messages.join(', ')
          unsaved_resources[issue] << resource
        end
      end unless resources.nil?
    end

    [saved_resources, unsaved_resources]
  end

  def safe_attributes=(attrs, user=User.current)
    if attrs.respond_to?(:to_unsafe_hash)
      attrs = attrs.to_unsafe_hash
    end

    return unless attrs.is_a?(Hash)
    assign_attributes delete_unsafe_attributes(attrs, user)
  end

  def full_date
    start ? "#{date}T#{start.strftime('%H:%M:%S')}" : nil
  end

  def full_date=(full)
    full = full.to_datetime
    self.date = full.strftime('%Y-%m-%d')
    self.start = full.strftime('%H:%M')
  rescue ArgumentError
  end

end
