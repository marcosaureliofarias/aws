class EasyEmailTemplate < ActiveRecord::Base
  include Redmine::SubclassFactory
  include Redmine::SafeAttributes

  validates_presence_of :name, :subject, :body_html

  safe_attributes *%w{ name subject body_html }

  def self.get_subclasses
    subclasses
  end

end
