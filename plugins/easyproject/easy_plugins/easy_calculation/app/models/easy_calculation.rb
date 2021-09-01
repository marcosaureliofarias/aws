class EasyCalculation < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project

  validates :project_id, :presence => true

  html_fragment :top_description, :scrub => :strip
  html_fragment :bottom_description, :scrub => :strip

  safe_attributes 'project_id',
    'top_description', 'bottom_description',
    'project_status',
    'supplier_name', 'supplier_tel', 'supplier_mail',
    'manager_name', 'manager_tel', 'manager_mail', 'title'

  def to_s
    self.project.name.to_s
  end

end
