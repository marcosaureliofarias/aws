module EasyExtensions
  module EasyLookups

    class EasyLookup
      include Redmine::I18n

      cattr_accessor :available, :entity_name
      @@available = {}

      def initialize
        raise NotImplementedError, 'You have to override attributes method.' if self.attributes.blank?
      end

      def attributes
        [[l(:label_link_with_and_custom_field, :attribute => l(:field_name)), 'name_and_cf']]
      end

      def translated_name
        l("easy_lookup.#{self.class.entity_name.underscore}.label")
      end

      class << self

        def map(&block)
          yield self
        end

        def register(class_string)
          easy_lookup_subclass = class_string.safe_constantize
          raise ArgumentError, '' unless easy_lookup_subclass.ancestors.include?(EasyExtensions::EasyLookups::EasyLookup)
          @@available[easy_lookup_subclass.entity_name] = easy_lookup_subclass
        end

        def available_lookups_by_type(type)
          @@available.values.select { |l| (l.except_for_type.blank? && l.only_for_type.blank?) ||
              (!l.except_for_type.blank? && !l.except_for_type.include?(type)) ||
              (!l.only_for_type.blank? && l.only_for_type.include?(type)) }
        end

        def available_lookup_by_entity_name(entity_name)
          @@available[entity_name]
        end

        def entity_name
          name[(name.rindex(':') + 1)..-1].sub('EasyLookup', '')
        end

        # Array of custom fields types that are disallowed (e.g. [DocumentCustomField, VersionCustomField, ...]
        def except_for_type
          []
        end

        # Array of custom fields types that are allowed (e.g. [ProjectCustomField, IssueCustomField, ...]
        def only_for_type
          []
        end

      end

    end

    class EasyLookupCollection
      include Redmine::I18n

      attr_reader :available, :custom_field

      def initialize(custom_field)
        @custom_field = custom_field
        @available    = {}
        create_for(custom_field.class)
      end

      def create_for(type)
        EasyExtensions::EasyLookups::EasyLookup.available_lookups_by_type(type).each do |easy_lookup_subclass|
          @available[easy_lookup_subclass] = easy_lookup_subclass.new
        end
      end

      def available_types
        available.values.collect { |l| [l.translated_name, l.class.entity_name] }.sort_by { |c| c[0] }.unshift(['', ''])
      end

      def entity_type
        custom_field.settings['entity_type'].presence || available_types.first[1]
      end

      def attribute_options
        lookup = EasyExtensions::EasyLookups::EasyLookup.available_lookup_by_entity_name(entity_type)
        lookup.nil? ? [] : available[lookup].attributes
      end

    end
  end
end
