module EasyGraphql
  module Mutations
    class CustomValueChange < ::EasyGraphql::Mutations::Base
      description 'Create/update CustomValue for Entity.'

      argument :entity_id, ID, required: true
      argument :entity_type, String, required: true
      argument :custom_field_id,  ID, required: true
      argument :value, GraphQL::Types::JSON, required: true

      field :custom_value, EasyGraphql::Types::CustomValue, null: true
      field :errors, [String], null: false

      def resolve(entity_id:, entity_type:, custom_field_id:, value:)
        return response(errors: [::I18n.t('easy_graphql.record_not_found')]) unless find_entity(entity_id, entity_type)

        @entity.init_journal(::User.current) if @entity.respond_to?(:init_journal)
        assign_value(entity_type, custom_field_id, value)
        if @entity.save
          response(custom_value: get_custom_value(custom_field_id))
        else
          response(errors: @entity.errors.full_messages)
        end
      end

      private

      def assign_value(entity_type, custom_field_id, value)
        case entity_type
        when 'Issue'
          @entity.safe_attributes = { 'custom_field_values' => { custom_field_id => value } }
        else
          @entity.custom_field_values = { custom_field_id => value }
        end
      end

      def get_custom_value(id)
        @entity.visible_custom_field_values.find { |cfv| cfv.custom_field.id == id.to_i }
      end

      def response(custom_value: nil, errors: [])
        { custom_value: custom_value, errors: errors }
      end
    end
  end
end
