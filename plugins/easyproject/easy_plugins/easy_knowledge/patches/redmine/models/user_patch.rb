module EasyKnowledge
  module UserPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        has_many :derived_easy_knowledge_stories, :as => :entity, :class_name => 'EasyKnowledgeStory', :dependent => :destroy
        has_many :easy_knowledge_categories, -> { order(:lft) }, :as => :entity, :dependent => :destroy

        has_many :easy_knowledge_assigned_stories, :as => :entity, :dependent => :destroy
        has_many :easy_knowledge_stories, :through => :easy_knowledge_assigned_stories

        has_many :favorite_easy_knowledge_stories, lambda{ distinct }, :through => :easy_favorites, :source => :entity, :source_type => 'EasyKnowledgeStory', :dependent => :destroy

        before_destroy :remove_kb_references

        def assigned_knowledge_story?(story)
          easy_knowledge_assigned_stories.where(:story_id => story.id).any?
        end

        def unread_easy_knowledge_stories
          # Assigned story already have read_date
          # This is for `acts_as_user_readable`
          # easy_knowledge_stories.joins("LEFT JOIN #{EasyUserReadEntity.table_name} ON #{EasyUserReadEntity.table_name}.entity_id = #{EasyKnowledgeStory.table_name}.id").where(["#{EasyUserReadEntity.table_name}.user_id <> #{self.id} OR #{EasyUserReadEntity.table_name}.id IS NULL"])

          easy_knowledge_stories.where(["#{EasyKnowledgeAssignedStory.table_name}.read_date IS NULL"])
        end

        def unread_easy_knowledge_stories?
          unread_easy_knowledge_stories.any?
        end

        def remove_kb_references
          return if self.id.nil?
          substitute = User.anonymous
          EasyKnowledgeStory.where(:author_id => id).update_all(:author_id => substitute.id)
          EasyKnowledgeCategory.where(:author_id => id).update_all(:author_id => substitute.id)
          EasyKnowledgeAssignedStory.where(:author_id => id).update_all(:author_id => substitute.id)
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'User', 'EasyKnowledge::UserPatch'
