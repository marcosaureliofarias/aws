module EasyActions
  module EasyActionEntity
    extend ActiveSupport::Concern

    included do

      store :action_settings, coder: JSON

      safe_attributes 'name', 'action_class', 'action_settings'

      validates :action_class, presence: true
      validates_associated :action

      def action
        return nil if action_class.blank?

        if action_class_changed? || @action.nil?
          @action = action_class.safe_constantize&.new(action_settings)
        end
        @action
      end

      def fire
        action&.fire(self)
      end

      def fire_on(entity)
        action&.fire(entity)
      end

    end

    class_methods do
    end

  end
end
