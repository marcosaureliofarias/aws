module EasyActions
  module Model
    extend ActiveSupport::Concern

    included do

      scope :visible, lambda { |*args| where(visible_condition(args.shift || User.current, *args)) }

    end

    class_methods do

      def visible_condition(user, options = {})
        "1=1"
      end

    end

    def project
      nil
    end

    def deletable?(user = nil)
      user ||= User.current
      user.allowed_to?(:manage_easy_actions, project, global: true)
    end

    def editable?(user = nil)
      user ||= User.current
      user.allowed_to?(:manage_easy_actions, project, global: true)
    end

    def visible?(user = nil)
      user ||= User.current
      user.allowed_to?(:view_easy_actions, project, global: true)
    end

  end
end
