module EasyActions
  module Conditions
    class Base
      include ActiveModel::Model

      def can_pass?(easy_action_sequence_instance)
        evaluate(easy_action_sequence_instance.entity)
      end

      def target_entity_class
        ActiveRecord::Base
      end

      def new_entities_for(easy_action_sequence)
        []
      end

      def to_partial_path
        view_folder + '/' + view_name
      end

      def view_folder
        "easy_action_conditions"
      end

      def view_name
        self.class.name.demodulize.underscore + "_form"
      end

      protected

      def evaluate(entity)
        true
      end

      def entities_already_in_instances_sql(easy_action_sequence)
        easy_action_sequence.instances.where(entity_type: target_entity_class).select(:entity_id)
      end

    end
  end
end
