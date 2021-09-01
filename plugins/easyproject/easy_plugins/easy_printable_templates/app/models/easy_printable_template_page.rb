class EasyPrintableTemplatePage < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :easy_printable_template

  acts_as_positioned :scope => :easy_printable_template_id

end
