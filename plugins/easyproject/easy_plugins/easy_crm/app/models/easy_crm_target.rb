class EasyCrmTarget < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :easy_crm_case
  belongs_to :project

end
