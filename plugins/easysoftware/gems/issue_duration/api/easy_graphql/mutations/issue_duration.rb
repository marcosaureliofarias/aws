module EasyGraphql
  module Mutations
    class IssueDuration < Base
      description 'Recalculate duration fields on issue.'

      argument :id, ID, required: false
      argument :attributes, GraphQL::Types::JSON, required: false
      argument :changing, GraphQL::Types::JSON, required: false
      argument :to_be_saved, Boolean, required: false

      field :issue, Types::Issue, null: true
      field :errors, [Types::Error], null: true

      def resolve(attributes: {}, changing: {}, id: nil, to_be_saved: true)
        self.entity = prepare_issue(id)
        return response_record_not_found unless entity

        if id
          entity.init_journal(::User.current)
          entity.safe_attributes = attributes unless to_be_saved
          recalculate_duration_fields(changing)
          to_be_saved ? entity.save : check_validity
        else
          entity.safe_attributes = attributes
          recalculate_duration_fields(changing)
          check_validity
        end

        response_all
      end

      private

      def check_validity
        entity.valid?
        entity.editable_custom_field_values(::User.current).each(&:validate_value)
      end

      def recalculate_duration_fields(attr)
        if attr['start_date']
          return entity.start_date = '' unless attr['start_date'].present?

          entity.start_date = ::Date.safe_parse(attr['start_date'])
          calculate_duration if entity.due_date
        elsif attr['due_date']
          return entity.due_date = '' unless attr['due_date'].present?

          entity.due_date = ::Date.safe_parse(attr['due_date'])
          calculate_duration if entity.start_date
        elsif attr['easy_duration'] && attr['easy_duration_time_unit']
          if entity.start_date
            entity.due_date = ::IssueEasyDuration.move_date(attr['easy_duration'], attr['easy_duration_time_unit'], entity.start_date, nil)
            calculate_duration
          elsif entity.due_date
            entity.start_date = ::IssueEasyDuration.move_date(attr['easy_duration'], attr['easy_duration_time_unit'], nil, entity.due_date)
            calculate_duration
          end
        end
      end

      def calculate_duration
        entity.easy_duration = ::IssueEasyDuration.easy_duration_calculate(entity.start_date, entity.due_date)
      end

      def prepare_issue(id)
        if id
          ::Issue.visible.find_by(id: id)
        else
          ::Issue.new
        end
      end

    end
  end
end
