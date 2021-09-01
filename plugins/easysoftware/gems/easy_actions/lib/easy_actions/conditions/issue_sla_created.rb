module EasyActions
  module Conditions
    class IssueSlaCreated < ::EasyActions::Conditions::Base

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
