class EasyKnowledgeAssignedStory < ActiveRecord::Base

  belongs_to :easy_knowledge_story, :class_name => 'EasyKnowledgeStory', :foreign_key => 'story_id'
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :entity, :polymorphic => true

  belongs_to :user, :foreign_key => 'entity_id', :foreign_type => 'Principal'
  belongs_to :project, :foreign_key => 'entity_id', :foreign_type => 'Project'
  belongs_to :issue, :foreign_key => 'entity_id', :foreign_type => 'Issue'

  after_initialize :set_default_values

  validates :author_id, :entity_id, :entity_type, :story_id, :presence => true

  scope :by_entity, lambda {|entity_type, entity_id| includes([:story, :author]).where(:entity_type => entity_type, :entity_id => entity_id)}

  scope :users, lambda {where(:entity_type => 'Principal')}
  scope :issues, lambda {where(:entity_type => 'Issue')}
  scope :project, lambda {where(:entity_type => 'Project')}

  def set_default_values
    self.author_id ||= User.current.id if new_record?
  end

end
