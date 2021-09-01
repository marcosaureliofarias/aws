module EasyActions
  module Conditions
    class EasyGitCodeRequestCreated < ::EasyActions::Conditions::Base

      def target_entity_class
        EasyGitCodeRequest
      end

      def new_entities_for(easy_action_sequence)
        easy_action_sequence.entity.easy_git_code_requests.status_opened.where.not(id: entities_already_in_instances_sql(easy_action_sequence))
      end

      protected

      def evaluate(entity)
        entity.status_opened?
      end

    end
  end
end
