class EasyKnowledgeStoryVersion < ActiveRecord::Base
  belongs_to :container, :polymorphic => true
  belongs_to :easy_knowledge_story, :class_name  => "::EasyKnowledgeStory", :foreign_key => 'easy_knowledge_story_id'
  belongs_to :author, :class_name => 'User'
end