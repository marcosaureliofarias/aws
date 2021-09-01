module RedmineTestCases
  module EntityAttributeHelperPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :format_html_issue_attribute, :redmine_test_cases

        def format_html_test_case_attribute(entity_class, attribute, unformatted_value, options={})
          if (attribute.is_a?(EasyQueryColumn)) && options[:entity]
            @test_case_formatter ||= TestCaseFormatter.new(self)
            @test_case_formatter.format_column(attribute, options[:entity])
          else
            format_html_default_entity_attribute(attribute, unformatted_value, options)
          end

        end

        def format_html_test_case_issue_execution_attribute(entity_class, attribute, unformatted_value, options={})
          if attribute.is_a?(EasyEntityAttribute) && options[:entity]
            @test_case_issue_execution_formatter ||= TestCaseIssueExecutionFormatter.new(self)
            @test_case_issue_execution_formatter.format_column(attribute, options[:entity])
          else
            format_html_default_entity_attribute(attribute, unformatted_value, options)
          end

        end

        def format_html_test_plan_attribute(entity_class, attribute, unformatted_value, options={})
          if attribute.is_a?(EasyEntityAttribute) && options[:entity]
            @test_plan_formatter ||= TestPlanFormatter.new(self)
            @test_plan_formatter.format_column(attribute, options[:entity])
          else
            format_html_default_entity_attribute(attribute, unformatted_value, options)
          end
        end

        def format_test_case_attribute(entity_class, attribute, unformatted_value, options={})
          if unformatted_value.is_a?(ActiveRecord::Associations::CollectionProxy)
            case attribute.name
            when :issues
              unformatted_value.to_a.map{ |value| "\##{value.id} #{value.subject}" }.join(', ')
            else
              format_default_collection_proxy(attribute, unformatted_value, options)
            end
          else
            format_default_entity_attribute(attribute, unformatted_value, options)
          end
        end

        def format_test_plan_attribute(entity_class, attribute, unformatted_value, options={})
          if unformatted_value.is_a?(ActiveRecord::Associations::CollectionProxy)
            case attribute.name
            when :test_cases
              unformatted_value.to_a.map{ |value| "\##{value.id} #{value.name}" }.join(', ')
            else
              format_default_collection_proxy(attribute, unformatted_value, options)
            end
          else
            format_default_entity_attribute(attribute, unformatted_value, options)
          end
        end

        def format_default_collection_proxy(attribute, unformatted_value, options={})
          unformatted_value.to_a.map { |value| "#{value.to_s}" }.join(', ')
        end
      end
    end

    module InstanceMethods
      def format_html_issue_attribute_with_redmine_test_cases(entity_class, attribute, unformatted_value, options={})
        case attribute.name
        when :test_cases
          if unformatted_value.any? && options[:entity]
            if options[:no_link]
              unformatted_value.map(&:name).join(', ')
            else
              unformatted_value.collect { |test_case| link_to(test_case, test_case_path(test_case)) }.join(', ').html_safe
            end
          end
        else
          format_html_issue_attribute_without_redmine_test_cases(entity_class, attribute, unformatted_value, options)
        end
      end
    end

    module ClassMethods

    end

  end

end
RedmineExtensions::PatchManager.register_helper_patch 'EntityAttributeHelper', 'RedmineTestCases::EntityAttributeHelperPatch', if: proc {Redmine::Plugin.installed? :easy_extensions}
