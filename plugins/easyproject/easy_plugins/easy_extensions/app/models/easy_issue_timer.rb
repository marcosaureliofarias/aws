class EasyIssueTimer < ActiveRecord::Base

  belongs_to :user
  belongs_to :issue

  validates :user_id, :issue_id, :presence => true

  scope :running, lambda { |user_id = nil| user_id ? where(:end => nil, :user_id => user_id) : where(:end => nil) }
  scope :ordered, lambda { order(:start) }
  scope :visible, lambda { |*args|
    joins(:issue => :project).
        where(Project.allowed_to_condition(args.shift || User.current, :view_issues, *args))
  }

  delegate :project, :priority, :estimated_hours, :status, to: :issue, prefix: true, allow_nil: true

  def self.active?(project = nil)
    easy_setting = EasySetting.value('easy_issue_timer_settings', project)
    easy_setting.is_a?(Hash) && !!easy_setting[:active]
  end

  def play!
    if self.paused?
      # then unpause
      self.pause     += (Time.now - self.paused_at).seconds.to_f
      self.paused_at = nil
    else
      play_set_issue_from_settings

      begin
        self.issue.save!(:validate => false)
      rescue ActiveRecord::StaleObjectError
        self.issue.reload
        play_set_issue_from_settings
        self.issue.save!(:validate => false)
      end
    end

    return self
  end

  def pause!
    self.update_attribute(:paused_at, DateTime.now) unless self.paused?
  end

  def stop!
    setting = get_settings[:end]

    case setting[:assigned_to]
    when :last_user
      assigned_to = issue.last_user_assigned_to
    when :author
      assigned_to = issue.author
    else
      assigned_to = User.find_by(:id => setting[:assigned_to]) if setting[:assigned_to].present?
    end

    self.issue.assigned_to = assigned_to if assigned_to
    self.issue.status_id   = setting[:status_id] if setting[:status_id] && IssueStatus.exists?(setting[:status_id])
    self.issue.done_ratio  = setting[:done_ratio] if setting[:done_ratio]

    self.end = Time.now

    return self.destroy
  end

  def current_hours
    in_pause = if self.paused?
                 self.pause + (Time.now - self.paused_at)
               else
                 self.pause
               end

    ((Time.now - self.start) - in_pause.seconds) / 1.hour
  end

  def hours
    hour     = (((self.end - self.start) - self.pause.seconds).to_r / 1.hour.to_r)
    round_to = get_settings[:round].to_r
    hour     = hour.roundup(round_to) if round_to && round_to.to_f > 0.0
    hour.to_f.round(2)
  end

  # Edit self.start for setting show_time_entry_range_select
  def computed_start
    new_start = self.start.to_time
    new_start = new_start.round_min_to_quarters if EasyGlobalTimeEntrySetting.value('show_time_entry_range_select', User.current.roles_for_project(self.issue.project))
    new_start
  end

  # Change end for range time
  def computed_end
    # round_to = get_settings[:round]
    # new_end = self.end.to_time
    # new_end += round_to.hour if round_to #&& User.current.user_time_entry_setting_range?
    # new_end
    new_end = self.computed_start + hours.hour
    new_end = new_end.round_min_to_quarters if EasyGlobalTimeEntrySetting.value('show_time_entry_range_select', User.current.roles_for_project(self.issue.project))
    new_end
  end

  def paused?
    !self.paused_at.nil?
  end

  def css_classes
    css = 'easy_issue_timer'
    css << ' ' + self.issue.css_classes if self.issue

    return css
  end

  private

  def get_settings
    return EasySetting.value('easy_issue_timer_settings', issue.project)
  end

  def play_set_issue_from_settings
    setting = get_settings[:start]

    self.issue.init_journal(User.current)

    self.issue.assigned_to = User.current if setting[:assigned_to_me]
    self.issue.status_id   = setting[:status_id] if setting[:status_id] && IssueStatus.exists?(setting[:status_id]) && self.issue.new_statuses_allowed_to(User.current).collect(&:id).include?(setting[:status_id])
  end

end
