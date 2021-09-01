module EasyActions
  module Conditions
    class EasyGitTestFailed < ::EasyActions::Conditions::Base

      def target_entity_class
        EasyGitTest
      end

      protected

      def evaluate(entity)
        true
      end

    end
  end
end
