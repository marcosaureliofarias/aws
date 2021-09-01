module EasyKnowledge
  module EasyQueryButtonsHelperPatch

    def self.included(base)
      base.class_eval do

        def easy_knowledge_story_query_additional_beginning_buttons(entity, options={})

          additional_buttons = ''
          if entity.unread?
            additional_buttons << content_tag(:span, content_tag(:span, l(:label_unread_entity), :class => 'tooltip'), :class => 'upper icon-message tooltip-parent icon-negative easy-knowledge-indicator')
          end

          return additional_buttons.html_safe
        end
      end
    end

  end
end

EasyExtensions::PatchManager.register_helper_patch 'EasyQueryButtonsHelper', 'EasyKnowledge::EasyQueryButtonsHelperPatch'
