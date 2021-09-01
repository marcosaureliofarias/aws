module EasyKnowledge
  module JournalPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :editable_by?, :easy_knowledge_story
        has_many :derived_easy_knowledge_stories, :as => :entity, :class_name => 'EasyKnowledgeStory', :dependent => :destroy

      end
    end

    module InstanceMethods

      def editable_by_with_easy_knowledge_story?(user)
        if journalized.is_a?(EasyKnowledgeStory)
          user && user.logged? && (user.allowed_to?(:manage_global_categories, project, global: true) || (self.user == user && user.allowed_to?(:manage_user_stories, project, global: true)))
        else
          editable_by_without_easy_knowledge_story?(user)
        end
      end

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Journal', 'EasyKnowledge::JournalPatch'
