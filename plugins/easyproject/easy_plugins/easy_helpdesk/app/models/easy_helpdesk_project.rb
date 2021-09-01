class EasyHelpdeskProject < ActiveRecord::Base
  include Redmine::SafeAttributes
  include EasyUtils::DateUtils

  LAST_POSSIBLE_AGGREGATED_START_DATE_DAY = 28

  belongs_to :project
  belongs_to :tracker
  belongs_to :assigned_to, :class_name => 'Principal', :foreign_key => 'assigned_to_id'
  belongs_to :default_for_mailbox, :class_name => 'EasyRakeTaskEasyHelpdeskReceiveMail', :foreign_key => 'default_for_mailbox_id'

  has_many :easy_helpdesk_project_matching, :dependent => :destroy
  has_many :easy_helpdesk_project_sla, :dependent => :destroy
  has_many :easy_helpdesk_auto_issue_closers, :dependent => :destroy

  validates :project, :presence => true
  validates :tracker, :presence => true
  validates :keyword, :length => { :maximum => 255 }
  validates_numericality_of :monthly_hours, :aggregated_hours_remaining, :allow_nil => true, :message => :invalid
  validates_uniqueness_of :project_id, :allow_nil => false
  validates_uniqueness_of :default_for_mailbox_id, :allow_nil => true
  validate :aggregated_start_date_validation

  accepts_nested_attributes_for :easy_helpdesk_project_matching, :allow_destroy => true
  accepts_nested_attributes_for :easy_helpdesk_project_sla, :allow_destroy => true
  accepts_nested_attributes_for :easy_helpdesk_auto_issue_closers, :allow_destroy => true

  serialize :watchers_ids, Array
  serialize :watcher_groups_ids, Array

  acts_as_customizable

  before_save :init_aggregated_hours
  before_validation :fix_aggregated_start_date

  safe_attributes 'project_id', 'default_for_mailbox_id', 'tracker_id', 'assigned_to_id', 'monthly_hours',
    'monitor_due_date', 'monitor_spent_time', 'watchers_ids', 'watcher_groups_ids', 'email_header', 'email_footer',
    'easy_helpdesk_project_matching_attributes', 'easy_helpdesk_project_sla_attributes', 'easy_helpdesk_auto_issue_closers_attributes',
    'aggregated_hours', 'aggregated_hours_start_date', 'aggregated_hours_period', 'aggregated_hours_remaining',
    'keyword','position', 'automatically_issue_closer_enable'

  def self.css_icon
    'icon icon-help-bubble easy-helpdesk'
  end

  def self.find_by_from_and_to(from, to, mailbox_username = nil)
    emails_from = Array(from)
    emails_to = Array(to)

    founded_ehp = nil
    ehp_scope = EasyHelpdeskProject.joins(:easy_helpdesk_project_matching).joins(:project).where(projects: {status: [Project::STATUS_ACTIVE, Project::STATUS_PLANNED]})

    # find by FROM - complete email (from user@domain.com, looking for entry with user@domain.com)
    founded_ehp ||= self.find_by_complete_email(ehp_scope, emails_from, 'from')

    # find by TO - complete email (to support@domain.com, looking for entry with support@domain.com)
    founded_ehp ||= self.find_by_complete_email(ehp_scope, emails_to, 'to')

    # find by FROM - look for domain name (from user@domain.com, looking for entry with domain.com)
    founded_ehp ||= self.find_by_domain_name(ehp_scope, emails_from, 'from')

    # find by TO - look for domain name (to support@domain.com, looking for entry with domain.com)
    founded_ehp ||= self.find_by_domain_name(ehp_scope, emails_to, 'to')

    # Nothing found, look for default project for mailbox
    unless founded_ehp
      mailbox = EasyRakeTaskEasyHelpdeskReceiveMail.find_by_username(mailbox_username)
      founded_ehp ||= mailbox.default_for_helpdesk_project if mailbox
    end

    founded_ehp
  end

  def self.find_by_email(email, mailbox_username = nil)
    find_by_from_and_to(email.from, email.to, mailbox_username)
  end

  def self.domain_condition(domain_name, email_field)
    where(["#{EasyHelpdeskProjectMatching.table_name}.domain_name = ? AND #{EasyHelpdeskProjectMatching.table_name}.email_field = ?", domain_name, email_field])
  end

  def self.find_by_complete_email(ehp_scope, emails, email_field)
    emails.each do |email|
      founded_ehp = ehp_scope.send(:domain_condition, self.parse_email(email), email_field).first
      return founded_ehp if founded_ehp
    end
    nil
  end

  def self.find_by_domain_name(ehp_scope, emails, email_field)
    emails.each do |email|
      domain_name = self.parse_email(email).match(/\A\S+@(\S+)\z/)
      founded_ehp = ehp_scope.send(:domain_condition, domain_name[1], email_field).first if domain_name
      return founded_ehp if founded_ehp
    end
    nil
  end

  def self.parse_email(email)
    email.to_s.strip.downcase
  end

  def self.detect_keyword(keyword, subject)
    return true if keyword == '*'
    keywords = keyword.split(',').inject([]) { |mem, var| var = var.strip; mem << var if !var.blank?; mem }
    !keywords.detect{|k| subject.include?(k)}.nil?
  end

  def self.find_by_keyword(subject)
    tbl = self.table_name
    self.where(["#{tbl}.keyword IS NOT NULL AND #{tbl}.keyword <> ?", '']).to_a.detect do |hp|
      self.detect_keyword(hp.keyword.strip, subject)
    end
  end

  def self.easy_helpdesk_issue_timeentries(project_id = nil, date_from = nil, date_to = nil)
    easy_helpdesk_issue_timeentries = TimeEntry.joins(:issue).where(:entity_type => 'Issue')
    if project_id
      easy_helpdesk_issue_timeentries = easy_helpdesk_issue_timeentries.where(:project_id => project_id).
                                          where("#{Issue.table_name}.tracker_id IN (#{self.trackers {|scope| scope.where(:project_id => project_id)}.select(:id).to_sql})")
    else
      easy_helpdesk_issue_timeentries = easy_helpdesk_issue_timeentries.joins(:project => :easy_helpdesk_project)
    end
    if date_from && date_to
      begin
        unless date_from.is_a?(Date) || date_to.is_a?(Date)
          date_from = Date.parse(date_from); date_to = Date.parse(date_to)
        end
        easy_helpdesk_issue_timeentries = easy_helpdesk_issue_timeentries.where(["#{TimeEntry.table_name}.spent_on BETWEEN ? AND ?", date_from, date_to])
      rescue
      end
    end
    easy_helpdesk_issue_timeentries
  end

  def self.trackers
    ehp_t = EasyHelpdeskProject.table_name
    sla_t = EasyHelpdeskProjectSla.table_name
    trac_t = Tracker.table_name
    subs = EasyHelpdeskProject.
    joins("LEFT OUTER JOIN #{sla_t} ON #{ehp_t}.id = #{sla_t}.easy_helpdesk_project_id").
    where("(#{trac_t}.id = #{ehp_t}.tracker_id OR #{trac_t}.id = #{sla_t}.tracker_id)")
    subs = yield subs if block_given?
    Tracker.where("EXISTS (#{subs.to_sql})")
  end

  def self.tracker_ids
    self.trackers.pluck(:id)
  end

  def watchers_ids
    if project
      super & project.users.map{|u| u.id.to_s}
    else
      super
    end
  end

  def watcher_groups_ids
    if project
      super & project.groups.map{|g| g.id.to_s}
    else
      super
    end
  end

  def parent_project
    self.project.parent
  end

  def remaining_hours
    ((self.aggregated_hours_remaining || self.monthly_hours) || 0) - (self.spent_time_current_month || 0)
  end

  def spent_time_current_month
    self.easy_helpdesk_spent_time_by_period('current_month')
  end

  def spent_time_last_month
    self.easy_helpdesk_spent_time_by_period('last_month')
  end

  def easy_helpdesk_total_spent_time
    self.easy_helpdesk_spent_time_by_period('all')
  end

  def easy_helpdesk_spent_time_by_period(period)
    range = self.get_date_range('1', period)
    self.easy_helpdesk_spent_time(range[:from], range[:to])
  end

  def aggregated_from_last_period
    self.aggregated_hours_remaining - (self.monthly_hours || 0) if self.aggregated_hours_remaining
  end

  def easy_helpdesk_spent_time(date_from = nil, date_to = nil)
    self.class.easy_helpdesk_issue_timeentries(self.project_id, date_from, date_to).sum(:hours)
  end

  def trackers
    self.class.trackers{|scope| scope.where("#{EasyHelpdeskProject.table_name}.id = #{self.id}")}
  end

  def tracker_ids
    self.trackers.pluck(:id)
  end

  def initial_date
    Date.civil(Date.today.year, Date.today.month, self.aggregated_hours_start_date.try(:day) || 1)
  end

  private

  def init_aggregated_hours
    if self.aggregated_hours
      self.aggregated_hours_remaining ||= self.monthly_hours
      self.aggregated_hours_last_update ||= self.initial_date
      if !self.aggregated_hours_last_reset || self.aggregated_hours_start_date_changed?
        self.aggregated_hours_last_reset = self.aggregated_hours_start_date || self.initial_date
      end
    else
      self.aggregated_hours_period = nil
      self.aggregated_hours_start_date = nil
      self.aggregated_hours_remaining = nil
      self.aggregated_hours_last_update = nil
      self.aggregated_hours_last_reset = nil
    end
  end

  def fix_aggregated_start_date
    self.aggregated_hours_start_date = Date.today.beginning_of_month if (!self.aggregated_hours && ((self.aggregated_hours_start_date.try(:day) || 0) > LAST_POSSIBLE_AGGREGATED_START_DATE_DAY))
  end

  def aggregated_start_date_validation
    errors.add(:aggregated_hours_start_date, :invalid) if (self.aggregated_hours_start_date.try(:day) || 0) > LAST_POSSIBLE_AGGREGATED_START_DATE_DAY
  end

end
