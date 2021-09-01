class EasyChecklistTemplate < EasyChecklist
  validates_length_of :name, :maximum => 255
  validates :name, :presence => true

  def add_to_entity(entity)
    new_easy_checklist = self.dup.becomes!(EasyChecklist)
    new_easy_checklist.entity = entity
    new_easy_checklist.save
    self.easy_checklist_items.each do |easy_checklist_item|
      new_easy_checklist_item = easy_checklist_item.dup
      new_easy_checklist_item.author = User.current
      new_easy_checklist.easy_checklist_items << new_easy_checklist_item
    end
  end

  def is_template?
    true
  end

  def can_edit?(user=nil)
    user ||= User.current
    return true if user.admin? || projects.blank?

    !!projects.detect{|project| user.allowed_to?(:manage_easy_checklist_templates, project)}
  end

  def can_delete?(user=nil)
    can_edit?(user)
  end

end
