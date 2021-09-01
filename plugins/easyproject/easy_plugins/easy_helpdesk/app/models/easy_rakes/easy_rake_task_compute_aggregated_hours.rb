class EasyRakeTaskComputeAggregatedHours < EasyRakeTask

  def update_aggregated_hours
    EasyHelpdeskProject.where(:aggregated_hours => true).find_each(:batch_size => 50) do |project|
      date_lu = project.aggregated_hours_last_update
      date_id = project.initial_date
      if date_lu < (date_id << 1)
        diff = self.distance_to(date_id, date_lu)[:months]
        cumulated_hours = project.easy_helpdesk_spent_time(project.initial_date << diff, project.initial_date - 1) || 0
        project.aggregated_hours_remaining += ((project.monthly_hours || 0) * diff) - cumulated_hours if project.aggregated_hours_remaining
        project.aggregated_hours_last_update = project.initial_date
        project.save
      end
    end
  end

  def reset_aggregated_hours
    EasyHelpdeskProject.where(:aggregated_hours => true).find_each(:batch_size => 50) do |project|
      period_start_date = Date.civil(Date.today.year, Date.today.month,
        project.aggregated_hours_start_date.try(:day) || 1) << self.period_mapping[project.aggregated_hours_period]
      if project.aggregated_hours_last_reset < period_start_date
        project.aggregated_hours_remaining = project.monthly_hours
        project.aggregated_hours_last_reset = project.initial_date
        project.save
      end
    end
  end

  def period_mapping
    {'quarterly' => 3,
     'half-yearly' => 6,
     'yearly' => 12}
  end

  def distance_to(d1, d2)
    years = d1.year - d2.year
    months = d1.month - d2.month
    days = d1.day - d2.day
    if days < 0
      days += 30
      months -= 1
    end
    if months < 0
      months += 12
      years -= 1
    end
    {:years => years, :months => months, :days => days}
  end

  def execute
    update_aggregated_hours
    reset_aggregated_hours

    return true
  end

  def category_caption_key
    :easy_helpdesk_name
  end

  def registered_in_plugin
    :easy_helpdesk
  end

end

