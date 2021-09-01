module EasyGraphql
  module Mutations
    class EasyChecklistDestroy < Base
      description 'Destroy an easy checklist.'

      argument :id, ID, required: true

      field :errors, [String], null: true

      def resolve(id:)
        @id = id
        errors = []
        return { errors: [I18n.t('easy_graphql.record_not_found')] } unless find_checklist

        if @checklist.can_edit?
          @checklist.destroy
        else
          errors << I18n.t('easy_graphql.not_authorized')
        end

        { errors: errors }
      end

      def find_checklist
        @checklist = ::EasyChecklist.visible.find_by(id: @id)
      end

    end
  end
end
