class EasyCrmCountryValue < ActiveRecord::Base
  include Redmine::SafeAttributes

  scope :visible, lambda { |*args|
    where(EasyCrmCountryValue.visible_condition(args.shift || User.current, *args))
  }

  scope :sorted, lambda { order("#{table_name}.country ASC") }

  acts_as_customizable

  safe_attributes 'country'
  safe_attributes 'custom_field_values', 'custom_fields'

  def self.visible_condition(user, options={})
    '1=1'
  end

  def self.css_icon
    'icon icon-user'
  end

  def self.find_by_country(country)
    EasyCrmCountryValue.where(country: country).first
  end

  def project
    nil
  end

  def visible?(user = nil)
    false
  end

  def editable?(user = nil)
    false
  end

  def deletable?(user = nil)
    false
  end

  def attachments_visible?(user = nil)
    visible?(user)
  end

  def attachments_editable?(user = nil)
    editable?(user)
  end

  def attachments_deletable?(user = nil)
    deletable?(user)
  end

  def to_s
    country.to_s
  end

end
