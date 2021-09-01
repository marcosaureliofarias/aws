class AlertType < ActiveRecord::Base
  self.table_name = 'easy_alert_types'

  default_scope{order("#{AlertType.table_name}.position ASC")}

  has_many :alerts, :class_name => 'Alert', :foreign_key => 'type_id'

  scope :named, lambda {|keyword| where(self.arel_table[:name].lower.eq(keyword.to_s.strip.downcase)) }

  acts_as_positioned

  validates :name, :presence => true
  validates :color, :presence => true

  before_save :change_default

  def self.default
    AlertType.where(:is_default => true).first
  end

  def translated_name
    l("alerts_type_#{self.name}").html_safe
  end

  private

  def change_default
    if respond_to?(:is_default) && self.is_default? && self.is_default_changed?
      AlertType.update_all(:is_default => false)
    end
  end

end
