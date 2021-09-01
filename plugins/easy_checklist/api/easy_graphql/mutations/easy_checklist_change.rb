module EasyGraphql
  module Mutations
    class EasyChecklistChange < Base
      description 'create(required -> name, entityId, entityType) /
                   update(required -> id, name) an easy checklist.'

      argument :id, ID, required: false
      argument :name, String, required: true
      argument :entity_id, ID, required: false
      argument :entity_type, String, required: false

      field :easy_checklist, EasyGraphql::Types::EasyChecklist, null: true
      field :errors, [String], null: true

      def resolve(id: nil, name: nil, entity_id: nil, entity_type: nil)
        @id = id
        @name = name
        @entity_id = entity_id
        @entity_type = entity_type

        if missing_required_fields?
          response(errors: [I18n.t(:error_required_fields_missing)])
        else
          prepare_checklist
          return response(errors: [I18n.t('easy_graphql.record_not_found')]) if missing_record?

          return response(errors: [I18n.t('easy_graphql.not_authorized')]) unless @checklist.can_edit?

          @checklist.name = @name
          if @checklist.save
            response(easy_checklist: @checklist)
          else
            response(errors: @checklist.errors.full_messages)
          end
        end
      end

      def missing_record?
        @id ? !@checklist : !@checklist.entity
      end

      def missing_required_fields?
        if @id
          false
        else
          !(@entity_id && @entity_type)
        end
      end

      def prepare_checklist
        @checklist = if @id
                       ::EasyChecklist.visible.find_by(id: @id)
                     else
                       ::EasyChecklist.new(entity_id: @entity_id, entity_type: @entity_type)
                     end
      end

      def response(easy_checklist: nil, errors: [])
        { easy_checklist: easy_checklist, errors: errors }
      end
    end
  end
end
