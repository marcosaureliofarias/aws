class EasyKnowledgeStoryCategory < ActiveRecord::Base

  belongs_to :story, :class_name => 'EasyKnowledgeStory', :foreign_key => 'story_id'
  belongs_to :category, :class_name => 'EasyKnowledgeCategory', :foreign_key => 'category_id'

end
