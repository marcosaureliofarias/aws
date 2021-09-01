class EasyCalculationItem < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project

  validates :project_id, :name, :presence => true
  validates :hours, :rate, :value, :calculation_discount, :numericality => true, :allow_nil => true

  safe_attributes 'name', 'hours', 'rate', 'value', 'unit', 'calculation_discount', 'calculation_discount_is_percent'

  before_create :set_default_position

  def to_s
    name.to_s
  end

  def set_default_position
    if !calculation_position && project
      last_entity = project.solution_entities.reverse.detect{|e| e.calculation_position.present?}
      if last_entity
        self.calculation_position = last_entity.calculation_position + 1
      else
        self.calculation_position = 1
      end
    end
  end

end
