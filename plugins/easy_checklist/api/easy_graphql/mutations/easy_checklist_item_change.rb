module EasyGraphql
  module Mutations
    class EasyChecklistItemChange < Base
      description 'create(required -> subject, checklistId) /
                   update(required -> id, (subject || done)) an easy checklist.'

      argument :id, ID, required: false
      argument :subject, String, required: false
      argument :done, Boolean, required: false
      argument :checklist_id, ID, required: false

      field :easy_checklist_item, EasyGraphql::Types::EasyChecklistItem, null: true
      field :errors, [String], null: true

      def resolve(id: nil, subject: nil, done: nil, checklist_id: nil)
        @id = id
        @done = done
        @subject = subject
        @checklist_id = checklist_id

        if missing_required_fields?
          response(errors: [I18n.t(:error_required_fields_missing)])
        else
          prepare_checklist_item
          return response(errors: [I18n.t('easy_graphql.record_not_found')]) unless @checklist_item

          @id ? resolve_update : resolve_save
        end
      end

      def resolve_update
        @checklist_item.subject = @subject if @subject
        if @done
          if @checklist_item.can_change?
            @checklist_item.done = @done
          else
            return response(errors: [::I18n.t('easy_graphql.not_authorized')])
          end
        end

        resolve_save
      end

      def resolve_save
        if @checklist_item.save
          response(easy_checklist_item: @checklist_item)
        else
          response(errors: @checklist_item.errors.full_messages)
        end
      end

      def missing_required_fields?
        if @id
          !(@done || @subject)
        else
          !(@subject && @checklist_id)
        end
      end

      def prepare_checklist_item
        if @id
          @checklist_item = ::EasyChecklistItem.find_by(id: @id)
        else
          @checklist = ::EasyChecklist.visible.find_by(id: @checklist_id)
          @checklist_item = @checklist.easy_checklist_items.build(subject: @subject) if @checklist
        end
      end

      def response(easy_checklist_item: nil, errors: [])
        { easy_checklist_item: easy_checklist_item, errors: errors }
      end
    end
  end
end
