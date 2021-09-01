module EasyIntegrations
  module Categories
    class Base
      extend ActiveModel::Translation

      class_attribute :slug

      def name
        self.class.human_attribute_name('name')
      end

      def description
        self.class.human_attribute_name('description')
      end

      def easy_integrations
        @easy_integrations ||= ::EasyIntegrations.for_category(self)
      end

    end
  end
end
