module EasyKnowledge
  module ProjectPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        has_many :derived_easy_knowledge_stories, :as => :entity, :class_name => 'EasyKnowledgeStory', :dependent => :destroy
        has_many :easy_knowledge_categories, -> { order(:lft) }, :as => :entity, :dependent => :destroy

        has_many :easy_knowledge_assigned_stories, :as => :entity, :dependent => :destroy
        has_many :easy_knowledge_stories, :through => :easy_knowledge_assigned_stories

        def copy_easy_knowledge(project)
          categories_map = {}

          self.easy_knowledge_stories = project.easy_knowledge_stories

          project.easy_knowledge_categories.order('parent_id, lft').each do |category|
            logger.info("category ##{category.id}") if logger
            new_category = EasyKnowledgeCategory.new
            new_category.copy_from(category)

            self.easy_knowledge_categories << new_category
            if new_category.new_record?
              logger.info "Project#copy_easy_knowledge: issue ##{category.id} could not be copied: #{new_category.errors.full_messages}" if logger
            else
              categories_map[category.id] = new_category
            end

            if category.parent_id
              if copied_parent = categories_map[category.parent_id]
                new_category.safe_attributes = {'parent_id' => copied_parent.id.to_s}
              end
            end

            category.stories.each do |story|
              story.easy_knowledge_category_ids += [categories_map[category.id].id]
            end

          end

          categories_map
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Project', 'EasyKnowledge::ProjectPatch'
