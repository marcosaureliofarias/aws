module EasyKnowledge
  module ProjectsHelperPatch
    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def count_easy_knowledge(project)
          count = project.easy_knowledge_categories.count
          project.easy_knowledge_categories.each do |category|
            count += category.stories.count
          end
          count
        end

      end
    end

    module InstanceMethods

    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'ProjectsHelper', 'EasyKnowledge::ProjectsHelperPatch'
