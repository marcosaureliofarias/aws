class EasyMoneyRatePriority < ActiveRecord::Base
  include Redmine::SafeAttributes
  self.table_name = 'easy_money_rate_priorities'

  default_scope{order("#{EasyMoneyRatePriority.table_name}.position ASC")}

  safe_attributes 'project_id', 'rate_type_id', 'position', 'entity_type', 'reorder_to_position'

  belongs_to :project, :class_name => "Project", :foreign_key => 'project_id'
  belongs_to :rate_type, :class_name => "EasyMoneyRateType", :foreign_key => 'rate_type_id'

  validates :rate_type_id, :presence => true

  acts_as_positioned

  scope :rate_priorities_by_project, lambda { |project_or_project_id| where(:project_id => project_or_project_id.is_a?(Project) ? project_or_project_id.id : project_or_project_id)} do
    def copy_to(project)
      project_id = project.is_a?(Project) ? project.id : project
      return if project_id.nil?
      each do |rate_priority|
        EasyMoneyRatePriority.create(:project_id => project_id, :rate_type_id => rate_priority.rate_type_id, :entity_type => rate_priority.entity_type) if EasyMoneyRatePriority.find_by_project_id_and_rate_type_id_and_entity_type(project_id, rate_priority.rate_type_id, rate_priority.entity_type).nil?
      end
    end
  end

  scope :rate_priorities_by_rate_type_and_project, lambda { |rate_type_id, project_id| where(:rate_type_id => rate_type_id, :project_id => project_id.presence)}

  def position_scope
    cond = ("rate_type_id = #{self.rate_type_id} AND project_id " + (self.project_id.blank? ? "IS NULL" : "= #{self.project_id}" ) )
    self.class.where(cond)
  end

  def position_scope_was
    method = destroyed? ? '_was' : '_before_last_save'
    rate_type_id_prev = send('rate_type_id' + method)
    project_id_prev = send('project_id' + method)
    cond = ("rate_type_id = #{rate_type_id_prev} AND project_id " + (project_id_prev.blank? ? "IS NULL" : "= #{project_id_prev}" ) )
    self.class.where(cond)
  end

end
