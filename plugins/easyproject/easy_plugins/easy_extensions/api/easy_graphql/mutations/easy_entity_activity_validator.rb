module EasyGraphql
  module Mutations
    class EasyEntityActivityValidator < Base
      description 'Expect all EasyEntityActivity attributes for new record.
                   Expect changed EasyEntityActivity attributes for edit record.
                   Return error object with validation messages.'

      argument :id, ID, required: false
      argument :attributes, GraphQL::Types::JSON, required: true

      field :easy_entity_activity, Types::EasyEntityActivity, null: true
      field :errors, [Types::Error], null: true

      def resolve(attributes:, id: nil)
        self.entity = prepare_easy_entity_activity(id)
        return response_record_not_found unless entity

        entity.safe_attributes = attributes
        entity.valid?

        response_all
      end

      private

        def prepare_easy_entity_activity(id)
          if id
            ::EasyEntityActivity.find_by(id: id)
          else
            ::EasyEntityActivity.new
          end
        end

    end
  end
end
