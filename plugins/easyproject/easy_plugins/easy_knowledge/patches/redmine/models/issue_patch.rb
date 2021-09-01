module EasyKnowledge
  module IssuePatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        has_many :derived_easy_knowledge_stories, :as => :entity, :class_name => 'EasyKnowledgeStory', :dependent => :destroy

        has_many :easy_knowledge_assigned_stories, :as => :entity, :dependent => :destroy
        has_many :easy_knowledge_stories, :through => :easy_knowledge_assigned_stories

        def assigned_knowledge_story?(story)
          easy_knowledge_assigned_stories.where(:story_id => story.id).any?
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Issue', 'EasyKnowledge::IssuePatch'
