module EasyGraphql
  module Mutations
    class EasyEntityActivity < Base
      description 'Create/update EasyEntityActivity.'

      argument :id, ID, required: false
      argument :attributes, GraphQL::Types::JSON, required: false
      argument :attendees, GraphQL::Types::JSON, required: false

      field :easy_entity_activity, Types::EasyEntityActivity, null: true
      field :errors, [Types::Error], null: true

      def resolve(attributes:, id: nil, attendees: {})
        self.entity = prepare_activity(id)
        return response_record_not_found unless entity

        build_attendees(attendees) unless attendees.empty?
        entity.safe_attributes = attributes

        if entity.save
          response_all
        else
          response_errors
        end
      end

      private

      def prepare_activity(id)
        if id
          ::EasyEntityActivity.find_by(id: id)
        else
          ::EasyEntityActivity.new
        end
      end

      def build_attendees(attendees)
        entity.easy_entity_activity_attendees.clear
        attendees.each do |entity_name, ids|
          entity_class = entity_name.safe_constantize
          if entity_class && entity_class < ActiveRecord::Base
            entity_class.where(id: ids).each do |attendee|
              entity.easy_entity_activity_attendees.build(entity: attendee)
            end
          end
        end
      end

    end
  end
end
