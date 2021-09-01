module EasyGraphql
  module Mutations
    class JournalNotes < Base
      description 'create(required -> notes, entityId, entityType) /
                   update(required -> id, notes) an journal.'

      argument :id, ID, required: false
      argument :entity_id, ID, required: false
      argument :entity_type, String, required: false
      argument :notes, String, required: true

      field :journal, EasyGraphql::Types::Journal, null: true
      field :errors, [String], null: true

      # TODO: add private comment
      def resolve(notes:, id: nil, entity_id: nil, entity_type: nil)
        if !(id || (entity_id && entity_type))
          response(errors: [I18n.t(:error_required_fields_missing)])
        else
          journal = prepare_journal(id, entity_id, entity_type)
          return response(errors: [I18n.t('easy_graphql.record_not_found')]) unless journal&.journalized

          journal.notes = notes
          if journal.save
            response(journal: journal)
          else
            response(errors: journal.errors.full_messages)
          end
        end
      end

      def prepare_journal(id, entity_id, entity_type)
        if id
          ::Journal.visible.find_by(id: id)
        else
          ::Journal.new(journalized_id: entity_id, journalized_type: entity_type, user: ::User.current)
        end
      end

      def response(journal: nil, errors: [])
        { journal: journal, errors: errors }
      end
    end
  end
end
