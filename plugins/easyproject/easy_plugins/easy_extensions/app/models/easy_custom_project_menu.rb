class EasyCustomProjectMenu < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project

  scope :originals, -> { where(EasyCustomProjectMenu.arel_table[:menu_item].not_eq(nil)) }
  scope :sorted, -> { order(:position) }
  scope :for_project, ->(project) { where(project_id: project) }

  acts_as_easy_translate
  acts_as_positioned :scope => :project_id

  safe_attributes 'name', 'url', 'reorder_to_position'

  def original_item?
    !menu_item.blank?
  end

end
