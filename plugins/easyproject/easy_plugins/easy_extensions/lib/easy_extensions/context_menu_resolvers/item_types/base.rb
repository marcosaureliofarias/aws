module ContextMenuResolvers
  module ItemTypes
    class Base

      # common attr
      attr_reader :name, :category, :icon, :url, :entity_name
      # url attr
      attr_reader :http_method, :confirm
      # list attr
      attr_reader :possible_values, :url_prop
      # autocomplete attr
      attr_reader :source, :source_root
      # custom field attr
      attr_reader :custom_field_id

      def initialize(attributes = {})
        # common attr
        @name             = attributes[:name]
        @category         = attributes[:category].presence || 'action'
        @icon             = attributes[:icon]
        @url              = attributes[:url]
        @entity_name      = attributes[:entity_name]

        # url attr
        @http_method      = attributes[:http_method] || 'GET'
        @confirm          = attributes[:confirm]

        # list attr
        @possible_values  = attributes[:possible_values]
        @url_prop         = attributes[:url_prop]

        # autocomplete attr
        @source           = attributes[:source]
        @source_root      = attributes[:source_root]

        # custom field attr
        @custom_field_id  = attributes[:custom_field_id]
      end

      def type
        raise NotImplementedError
      end

    end
  end
end
