class EasyDataTemplateAssignment < ActiveRecord::Base
  self.table_name = 'easy_data_template_assignments'

  belongs_to :datatemplate, :class_name => 'EasyDataTemplate', :foreign_key => 'easy_data_template_id'

  after_initialize :set_default_values

  validates :easy_data_template_id, :presence => true
  validates :entity_attribute_name, :presence => true
  validates :file_column_position, :numericality => true

  def set_default_values
    self.file_column_position ||= (datatemplate.assignments.collect(&:file_column_position).max.to_i + 1) unless datatemplate.nil?
  end

end
