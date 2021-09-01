module EasyActions
  module Conditions
    class EasyGitCodeRequestClosed < ::EasyActions::Conditions::Base

      def target_entity_class
        EasyGitCodeRequest
      end

      protected

      def evaluate(entity)
        entity.status_closed?
      end

    end
  end
end
