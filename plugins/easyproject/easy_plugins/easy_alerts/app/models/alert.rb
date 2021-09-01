class Alert < ActiveRecord::Base
  self.table_name = 'easy_alerts'

  default_scope{order("#{Alert.table_name}.position ASC")}

  belongs_to :type, :class_name => 'AlertType'
  belongs_to :rule, :class_name => 'AlertRule'
  belongs_to :author, :class_name => 'User'
  belongs_to :group, :class_name => 'Group'
  belongs_to :mail_group, :class_name => 'Group'

  has_many :reports, lambda { where(:archived => false) }, :foreign_key => 'alert_id', :class_name => 'AlertReport', :dependent => :delete_all
  has_many :archived_reports, lambda { where(:archived => true) }, :foreign_key => 'alert_id', :class_name => 'AlertReport', :dependent => :delete_all

  acts_as_positioned :scope => :author_id

  scope :user_alerts, lambda {|*args| preload([:author, :type]).where(Alert.user_alerts_condition(args.first || User.current))}
  scope :for_all, lambda {|*args| preload([:author, :type]).where(Alert.for_all_condition(args.first || User.current))}
  scope :nextrun, lambda {|time=Time.now| where(Alert.arel_table[:nextrun_at].eq(nil).or(Alert.arel_table[:nextrun_at].lteq(time)))}

  delegate :context_id, :to => :rule, :allow_nil => true

  serialize :rule_settings, EasyExtensions::UltimateHashSerializer
  serialize :period_options, EasyExtensions::UltimateHashSerializer

  after_initialize :set_default_values

  validate :alert_rule_validations
  validate :alert_validations

  validates :type_id, :context_id, :author_id, :rule_id, :presence => true
  validates :name, :length => 1..100, :allow_nil => false

  def self.user_alerts_condition(user)
    # t = Alert.arel_table
    # Alert.where(t[:is_for].in([:all,:only_me]).and(t[:author_id].eq(user.id).or(t[:is_for].eq(:group).and(t[:group_id].not_eq(nil).and(Group)))))
    "#{Alert.table_name}.is_for = 'all' OR (#{Alert.table_name}.is_for = 'only_me' AND #{Alert.table_name}.author_id = #{user.id}) OR (#{Alert.table_name}.is_for = 'group' AND #{Alert.table_name}.group_id IS NOT NULL AND EXISTS (SELECT * FROM groups_users WHERE groups_users.group_id = #{Alert.table_name}.group_id AND groups_users.user_id = #{user.id}))"
  end

  def self.for_all_condition(user)
    if user.admin?
      "1=1"
    else
      "#{Alert.table_name}.is_for = 'all'"
    end
  end

  def self.generate_reports_all
    Alert.nextrun.each {|alert| alert.generate_reports}
  end

  def self.builtin_for_plugin(plugin)
    case plugin
    when :EasyHelpdesk
      100
    when :Modification
      5000
    end
  end

  def set_nextrun_at(date = nil)
    if period_options['time'] == 'cron'
      self.nextrun_at =  nil
    else
      self.nextrun_at =  EasyUtils::DateUtils.calculate_from_period_options(date, period_options)
    end
  end

  def set_default_values
    if new_record?
      self.author_id ||= User.current.id
    end
  end

  def caption
    "#{self.type.translated_name}: #{self.name}".html_safe
  end

  def users
    return @users unless @users.nil?
    case self.is_for
    when 'only_me'
      @users = [self.author] if self.author&.active?
    when 'all'
      @users = User.active.to_a
    when 'group'
      if self.group
        @users = self.group.users.active.to_a
      end
    end
    @users || []
  end

  def editable_by?(user = nil)
    u = user || User.current

    if u.admin?
      return true
    elsif self.is_for == 'all' && u.allowed_to?(:manage_alerts_for_all, nil, :global => true)
      return true
    elsif self.author == u
      return true
    end

    return false
  end

  def deletable?
    builtin == 0
  end

  def can_generate_report?(user = nil)
    return true if self.users.include?(User.anonymous)
    return self.users.include?(user || User.current)
  end

  def generate_user_reports(user)
    user.execute do
      self.rule.generate_reports(self)

      if self.period_options['time'] == 'cron'
        new_nextrun_at = nil
      else
        new_nextrun_at = EasyUtils::DateUtils.calculate_from_period_options(Date.today, self.period_options)
      end

      self.update_attribute(:nextrun_at, new_nextrun_at) if self.nextrun_at != new_nextrun_at
    end

    return true
  end

  def generate_reports
    self.users.each do |user|
      self.generate_user_reports(user)
    end unless self.users.blank?
  end

  def mailer_template_name
    self.rule.mailer_template_name(self)
  end

  def issue_required?
    mail_for == 'assignees' || mail_for == 'coworkers'
  end

  private

  def alert_rule_validations
    self.rule.validate_alert(self) unless self.rule.nil?
  end

  def alert_validations
    errors.add(:mail, :blank) if self.mail_for == 'custom' && self.mail.blank?
  end

end
