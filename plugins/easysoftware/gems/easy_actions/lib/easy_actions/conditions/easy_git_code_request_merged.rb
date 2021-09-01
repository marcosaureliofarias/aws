module EasyActions
  module Conditions
    class EasyGitCodeRequestMerged < ::EasyActions::Conditions::Base

      def target_entity_class
        EasyGitCodeRequest
      end

      protected

      def evaluate(entity)
        entity.status_merged?
      end

    end
  end
end
