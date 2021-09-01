module EasyAgileBoard
  module EntityAttributeHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :format_html_issue_attribute, :easy_agile_board
        alias_method_chain :format_issue_attribute, :easy_agile_board

        def format_html_easy_sprint_attribute(entity_class, attribute, unformatted_value, options={})
          value = format_entity_attribute(entity_class, attribute, unformatted_value, options)
          case attribute.name
          when :name
            link_to unformatted_value, easy_agile_board_path(options[:entity].project_id, sprint_id: options[:entity])
          when :version, :project
            link_to_entity(unformatted_value) if unformatted_value.present?
          else
            value
          end
        end

      end
    end

    module InstanceMethods
      def format_html_issue_attribute_with_easy_agile_board(entity_class, attribute, unformatted_value, options={})
        case attribute.name
        when :'issue_easy_sprint_relation.easy_sprint'
          link_to unformatted_value.name, easy_agile_board_path(unformatted_value.project, sprint_id: unformatted_value) if unformatted_value && unformatted_value.is_a?(EasySprint)
        when :easy_story_points
          css_classes = ''
          if options[:entity].present? && options[:entity].safe_attribute?('easy_story_points')
            css_classes << 'multieditable'
          end
          content_tag(:span, unformatted_value, class: css_classes,
                      data: {
                        name: 'issue[easy_story_points]',
                        type: 'text',
                        value: (unformatted_value.nil? ? '' : unformatted_value)
                      }
          )
        else
          format_html_issue_attribute_without_easy_agile_board(entity_class, attribute, unformatted_value, options)
        end
      end

      def format_issue_attribute_with_easy_agile_board(entity_class, attribute, unformatted_value, options={})
        case attribute.name
        when :'issue_easy_sprint_relation.easy_sprint'
          unformatted_value.name if unformatted_value && unformatted_value.is_a?(EasySprint)
        else
          format_issue_attribute_without_easy_agile_board(entity_class, attribute, unformatted_value, options)
        end
      end
    end

  end

end
EasyExtensions::PatchManager.register_helper_patch 'EntityAttributeHelper', 'EasyAgileBoard::EntityAttributeHelperPatch'
