module EasyButtons
  module RedmineFieldFormatPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :query_filter_options, :easy_buttons
      end
    end

    module InstanceMethods

      def query_filter_options_with_easy_buttons(custom_field, *args)
        options = query_filter_options_without_easy_buttons(custom_field, *args)
        if custom_field.multiple?
          # Not supported
        else
          options[:attr_reader] = true
          options[:attr_writer] = true
        end
        options
      end

    end

    module ClassMethods
    end

  end
end

EasyExtensions::PatchManager.register_other_patch ['Redmine::FieldFormat::ListFormat', 'Redmine::FieldFormat::StringFormat', 'Redmine::FieldFormat::FloatFormat', 'Redmine::FieldFormat::IntFormat', 'Redmine::FieldFormat::BoolFormat', 'EasyExtensions::FieldFormats::EasyLookup', 'Redmine::FieldFormat::UserFormat'], 'EasyButtons::RedmineFieldFormatPatch'
