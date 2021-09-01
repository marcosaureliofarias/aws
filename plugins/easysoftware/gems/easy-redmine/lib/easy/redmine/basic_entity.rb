module Easy
  module Redmine
    module BasicEntity
      extend ActiveSupport::Concern

      included do
        include(::Easy::BasicEntity) unless include?(::Easy::BasicEntity)
        include(::Redmine::SafeAttributes) unless include?(::Redmine::SafeAttributes)

        scope :visible, lambda { |*args| where(visible_condition(args.shift || User.current, *args)) }

        class_attribute :permission_show, :permission_edit, :permission_destroy

      end

      class_methods do

        def human_attribute_name(attribute, **args)
          I18n.t("activerecord.attributes.#{self.base_class.name.underscore}.#{attribute}", **args, default: "field_#{attribute}")
        end

        def visible_condition(user, options = {})
          "1=1"
        end

      end

      def project
        nil
      end

      def visible?(user = nil)
        user ||= User.current
        user.allowed_to?(permission_show, project, global: true)
      end

      def editable?(user = nil)
        user ||= User.current
        user.allowed_to?(permission_edit, project, global: true)
      end

      def deletable?(user = nil)
        user ||= User.current
        user.allowed_to?(permission_destroy, project, global: true)
      end

      protected

      def permission_show
        self.class.permission_show || :view_x
      end

      def permission_edit
        self.class.permission_show || :view_x
      end

      def permission_destroy
        self.class.permission_show || :view_x
      end

    end
  end
end
