#
# THIS FILE MUST BE LOADED BEFORE IssueQuery OR EasyIssueQuery !!!
#
module EasyGantt
  module IssueRelationPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      start_to_start = 'start_to_start'
      finish_to_finish = 'finish_to_finish'
      start_to_finish = 'start_to_finish'

      new_types = base::TYPES.merge(

          start_to_start => {
            name: :label_start_to_start,
            sym_name: :label_start_to_start,
            order: 20,
            sym: start_to_start
          },

          finish_to_finish => {
            name: :label_finish_to_finish,
            sym_name: :label_finish_to_finish,
            order: 21,
            sym: finish_to_finish
          },

          start_to_finish => {
            name: :label_start_to_finish,
            sym_name: :label_start_to_finish,
            order: 22,
            sym: start_to_finish
          }

        )

      base.class_eval do
        const_set :TYPE_START_TO_START, start_to_start
        const_set :TYPE_FINISH_TO_FINISH, finish_to_finish
        const_set :TYPE_START_TO_FINISH, start_to_finish

        remove_const :TYPES
        const_set :TYPES, new_types.freeze

        inclusion_validator = _validators[:relation_type].find{|v| v.kind == :inclusion}
        inclusion_validator.instance_variable_set(:@delimiter, new_types.keys)

        alias_method_chain :handle_issue_order, :easy_gantt
      end
    end

    module InstanceMethods

      # +---------+   (5)    +---------+
      # | Issue 1 |--------->| Issue 2 |
      # +---------+          +---------+
      # (issue_from)         (issue_to)
      #
      def gantt_previous_latest_start
        if (IssueRelation::TYPE_PRECEDES == relation_type) && delay && issue_to && (issue_to.start_date || issue_to.due_date)
          (issue_to.start_date || issue_to.due_date) - 1 - delay
        end
      end

      def handle_issue_order_with_easy_gantt
        _delay = delay
        handle_issue_order_without_easy_gantt

        if relation_type == self.class::TYPE_START_TO_START ||
           relation_type == self.class::TYPE_FINISH_TO_FINISH ||
           relation_type == self.class::TYPE_START_TO_FINISH
          self.delay = _delay
        end
      end

    end

  end
end

IssueRelation.send(:include, EasyGantt::IssueRelationPatch)
