module EasyGraphql
  module Mutations
    class IssueValidator < Base
      description 'Expect all Issue attributes e.g. { subject: "issue subject", status_id: 1 } for new issue.
                   Expect change Issue attribute and ID for edit issue.
                   Return error object with validation messages.'

      argument :id, ID, required: false
      argument :attributes, GraphQL::Types::JSON, required: true

      field :issue, Types::Issue, null: true
      field :errors, [Types::Error], null: true

      def resolve(attributes:, id: nil)
        self.entity = prepare_issue(id)
        return response_record_not_found unless entity

        entity.safe_attributes = attributes
        entity.valid?
        entity.editable_custom_field_values(::User.current).each(&:validate_value)

        response_all
      end

      private

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
