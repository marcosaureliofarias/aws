module EasyGraphql
  module Mutations
    class EasyChecklistItemDestroy < Base
      description 'Destroy an easy checklist item.'

      argument :id, ID, required: true

      field :errors, [String], null: true

      def resolve(id:)
        if find_checklist_item(id)
          @checklist_item.destroy
          { errors: [] }
        else
          { errors: [I18n.t('easy_graphql.record_not_found')] }
        end
      end

      def find_checklist_item(id)
        @checklist_item = ::EasyChecklistItem.find_by(id: id)
      end

    end
  end
end
