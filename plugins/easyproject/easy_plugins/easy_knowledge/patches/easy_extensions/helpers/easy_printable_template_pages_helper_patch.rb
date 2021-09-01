module EasyKnowledge
  module EasyPrintableTemplatePagesHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        def easy_printable_template_page_create_replacable_tokens_from_entity_easy_knowledge_story(story)
          return {} unless story.is_a?(EasyKnowledgeStory)
          tokens = {}
          tokens['easy_knowledge_story_id'] = story.id
          tokens['easy_knowledge_story_author'] = story.author
          tokens['easy_knowledge_story_name'] = story.name
          tokens['easy_knowledge_story_description'] = story.description
          tokens['easy_knowledge_story_version'] = story.version
          tokens['easy_knowledge_story_created_on'] = story.created_on
          tokens['easy_knowledge_story_updated_on'] = story.updated_on

          story.visible_custom_field_values.each do |cf_value|
            tokens["easy_knowledge_story_cf_#{cf_value.custom_field.id}"] = show_value(cf_value)
          end

          tokens
        end
      end
    end

    module InstanceMethods

    end

  end

end

EasyExtensions::PatchManager.register_helper_patch 'EasyPrintableTemplatePagesHelper',
                                                   'EasyKnowledge::EasyPrintableTemplatePagesHelperPatch',
                                                   if: Proc.new { Redmine::Plugin.installed?(:easy_printable_templates) }
