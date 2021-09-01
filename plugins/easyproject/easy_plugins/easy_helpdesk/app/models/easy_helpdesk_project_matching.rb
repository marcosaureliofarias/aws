class EasyHelpdeskProjectMatching < ActiveRecord::Base

  EMAIL_FIELD_FROM = 'from'
  EMAIL_FIELD_TO = 'to'

  belongs_to :easy_helpdesk_project

  validates :email_field, :inclusion => [EasyHelpdeskProjectMatching::EMAIL_FIELD_FROM, EasyHelpdeskProjectMatching::EMAIL_FIELD_TO]
  validates :domain_name, :presence => true
  validates :domain_name, :uniqueness => { :scope => :email_field }, :if => Proc.new {|m| m.domain_name_changed? || m.email_field_changed? }

  def domain_name_with_email_field
    if domain_name.blank?
      ''
    else
      "#{self.domain_name} (#{l(:"label_email_field.#{self.email_field}")})"
    end
  end

end

