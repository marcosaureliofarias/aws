class EasyRakeTaskCheckFailureTasks < EasyRakeTask

  after_initialize :set_default_settings

  def execute

    failed_tasks = EasyRakeTask.includes(:easy_rake_task_infos).where({
                                                                          easy_rake_task_infos: {
                                                                              finished_at: day_to_search.beginning_of_day..day_to_search.end_of_day,
                                                                              status:      EasyRakeTaskInfo::STATUS_ENDED_FAILED
                                                                          }
                                                                      }).to_a

    EasyMailer.easy_rake_task_check_failure_tasks(self, failed_tasks).deliver if failed_tasks.any?

    true
  end

  def day_to_search
    return @day_to_search if @day_to_search
    @day_to_search = if Time.now.hour < 5
                       Date.today - 1.day
                     else
                       Date.today
                     end
    @day_to_search
  end

  def recepients
    if self.settings['email_type'] == 'email'
      self.settings['email']
    elsif self.settings['email_type'] == 'all_admins'
      User.active.where(id: self.settings['admins'])
    end
  end

  def settings_view_path
    "easy_rake_tasks/settings/#{self.class.name.underscore}"
  end

  private

  def set_default_settings
    return unless new_record?
    self.settings               ||= {}
    self.settings['email_type'] ||= 'all_admins'
    if self.settings['email_type'] == 'all_admins' && !self.settings.key?('admins')
      self.settings['admins'] = User.active.where(admin: true).pluck(:id).collect(&:to_s)
    end
  end

end
