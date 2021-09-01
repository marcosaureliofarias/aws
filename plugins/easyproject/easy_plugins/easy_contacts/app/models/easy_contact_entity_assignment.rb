class EasyContactEntityAssignment < ActiveRecord::Base
  belongs_to :entity, :polymorphic => true
  belongs_to :easy_contact

  belongs_to :user, :foreign_key => 'entity_id', :class_name => 'Principal'
  belongs_to :project, :foreign_key => 'entity_id', :class_name => 'Project'
  belongs_to :issue, :foreign_key => 'entity_id', :class_name => 'Issue'

  after_create :ensure_easy_contact, :if => Proc.new{|m| m.entity_type == 'Issue'}

  validates :easy_contact_id, uniqueness: { scope: [:entity_id, :entity_type], case_sensitive: true }

  private

  def ensure_easy_contact
    (self.issue.easy_contact_ids - self.issue.project.easy_contact_ids).each do |issue_contact_id|
      self.class.create(entity_id: self.issue.project_id, entity_type: 'Project', easy_contact_id: issue_contact_id)
    end
  end

end
