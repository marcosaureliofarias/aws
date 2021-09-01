module EasyKnowledge
  module IssuesHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def easy_knowledge_new_story_button(issue, entity_type, entity_id, name)
          options = {
            back_url: url_for(issue),
            easy_knowledge_story: {name: name, entity_type: entity_type, entity_id: entity_id},
          }
          url_options = if User.current.allowed_to?(:create_project_stories, issue.project)
            new_polymorphic_path([issue.project, :easy_knowledge_story], options)
          elsif User.current.allowed_to_globally?(:create_global_stories)
            new_polymorphic_path(:easy_knowledge_story, options)
          end
          if url_options
            confirm = EasyKnowledgeStory.where(entity_type: entity_type, entity_id: entity_id).exists? ? l(:text_are_you_really_sure_create_story) : false
            link_to(l(:button_easy_knowledge_mark_as_story_knowledge), url_options, { data: { confirm: confirm }, class: 'icon icon-bulb' })
          else
            ''
          end
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_helper_patch 'IssuesHelper', 'EasyKnowledge::IssuesHelperPatch'
