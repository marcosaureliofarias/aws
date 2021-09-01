module EasyActions
  module Conditions
    class IssueSlaExpiring < ::EasyActions::Conditions::Base

      def target_entity_class
        Issue
      end

      protected

      def evaluate(entity)
        true
      end

    end
  end
end
