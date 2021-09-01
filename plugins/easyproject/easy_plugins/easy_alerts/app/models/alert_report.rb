class AlertReport < ActiveRecord::Base
  self.table_name = 'easy_alert_reports'

  belongs_to :alert, :class_name => 'Alert', :foreign_key => 'alert_id'
  belongs_to :entity, :polymorphic => true
  belongs_to :user

  validates :alert_id, :presence => true

  scope :visible, lambda {|user=User.current| where(:user_id => user.id, :archived => false).joins({:alert => :type}).order("#{AlertType.table_name}.position ASC") }
  scope :archived, lambda {|user=User.current| where(:user_id => user.id, :archived => true).joins({:alert => :type}).order("#{AlertType.table_name}.position ASC") }
  scope :by_rules, lambda {|rules=AlertRule.active_rules| includes(alert: :rule).where(easy_alert_rules: {class_name: rules.map(&:to_s)}) }
  scope :by_type, lambda {|type_id| where(Alert.arel_table[:type_id].eq(type_id)) }
  scope :not_emailed, lambda { where(:emailed => false, :archived => false) }
  scope :sorted, lambda { order("#{AlertReport.table_name}.created_on DESC") }

  def self.archived_and_created_on_scope(days_count)
    AlertReport.where(['created_on <= ? AND archived = ?', Time.now - days_count.days, true])
  end

  def self.not_archived_and_expires_at_scope(days_count)
    AlertReport.where(['expires_at <= ? AND archived = ?', Time.now - days_count.days, false])
  end

  def self.purge_all(days_count)
    archived_and_created_on_scope(days_count).delete_all
    not_archived_and_expires_at_scope(days_count).delete_all
  end

  def self.delete_all_not_sent_reports
    archived_and_created_on_scope(7).not_emailed.delete_all
    not_archived_and_expires_at_scope(7).not_emailed.delete_all
  end

end
