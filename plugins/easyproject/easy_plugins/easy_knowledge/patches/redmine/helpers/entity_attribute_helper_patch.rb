module EasyKnowledge
  module EntityAttributeHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def format_html_easy_knowledge_story_attribute(entity_class, attribute, unformatted_value, options={})
          value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

          case attribute.name
          when :name
            if options[:no_link] || !options[:entity]
              h(value)
            else
              result = ActiveSupport::SafeBuffer.new
              result << link_to(value, easy_knowledge_story_path(options[:entity], :project_id => @project))
              result
            end
          when :projects
            truncate_objects(options[:entity].projects){ |project| project.to_a.map!{|p| link_to_project(p)}}
          when :issues
            truncate_objects(options[:entity].issues){ |issue| issue.to_a.map!{|i| link_to_issue(i)}}
          when :recomended_to
            truncate_objects(options[:entity].users){ |user| user.to_a.map!{|u| link_to_user(u)}}
          when :author
            content_tag(:span, render_user_attribute(unformatted_value, value, options)) if value
          else
            h(value)
          end

        end

        def format_easy_knowledge_story_attribute(entity_class, attribute, unformatted_value, options={})
          case attribute.name
          when :categories
            options[:entity].easy_knowledge_categories.map(&:name).join(', ')
          when :projects
            options[:entity].projects.map(&:name).join(', ') if options[:no_html]
          when :issues
            options[:entity].issues.map(&:subject).join(', ') if options[:no_html]
          when :recomended_to
            options[:entity].users.map(&:name).join(', ') if options[:no_html]
          else
            format_default_entity_attribute(attribute, unformatted_value, options)
          end
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_helper_patch 'EntityAttributeHelper', 'EasyKnowledge::EntityAttributeHelperPatch'
