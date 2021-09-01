# frozen_string_literal: true

module EasyGraphql
  module Mutations
    class MarkAsRead < Base
      description 'Mark as read for all entities'

      argument :entity_id, ID, required: true
      argument :entity_type, String, required: true

      field :errors, [String], null: true

      def resolve(entity_id:, entity_type:)
        entity_klass = entity_type.safe_constantize

        if !entity_klass
          return { errors: ["Entity doesn't exists"] }
        end

        if !entity_klass.method_defined?(:mark_as_read)
          return { errors: ['Entity cannot be makred as read'] }
        end

        entity = entity_klass.find_by(id: entity_id)

        if !entity
          return { errors: ["Entity doesn't exists"] }
        end

        entity.mark_as_read

        {
          errors: []
        }
      end

    end
  end
end
