module EasyIntegrations
  module Metadata
    class Base
      extend ActiveModel::Translation

      class_attribute :category_class

      def self.register(symbol, options = {})
        EasyIntegrations.register_metadata(symbol, self, options)
      end

      def category
        @category ||= category_class&.new
      end

      def name
        self.class.human_attribute_name('name')
      end

      def description
        self.class.human_attribute_name('description')
      end

      def icon
      end

      def available?
        true
      end

    end
  end
end
