module EasyGraphql
  module Mutations
    class EasyAttendanceCreate < Base
      description 'Create attendances'

      argument :user_ids, [ID], required: false
      argument :attributes, GraphQL::Types::JSON, required: true

      field :easy_attendance, Types::EasyAttendance, null: true
      field :errors, [Types::EasyAttendanceError], null: true

      attr_accessor :entities

      def resolve(attributes:, user_ids: nil)
        # Convert `Hash` to with  indifferent access for dates setters methods
        unless attributes.is_a?(ActionController::Parameters)
          attributes = attributes.with_indifferent_access
        end
        errors = []
        self.entities = []
        user_ids ||= [attributes['user_id']]
        ::EasyAttendance.transaction do
          user_ids.each do |user_id|
            self.entity = ::EasyAttendance.new(user_id: user_id)
            entity.safe_attributes = attributes.except('user_id')
            entity.non_work_start_time = attributes['non_work_start_time'] #should be setted after arrival
            user = entity.user
            if entity.can_edit?
              entity.ensure_easy_attendance_non_work_activity
              if entity.errors.blank? && entity.save
                entities << entity
              else
                errors += prepare_errors.each {|error| error[:user] = user }
              end
            else
              errors << { attribute: 'base', full_messages: [I18n.t('easy_graphql.not_authorized')], user: user }
            end
          end
          raise ::ActiveRecord::Rollback if errors.any? || entities.blank?
        end
        # easy_attendance is last record in array if multiple
        # easy_attendance is first working day attendance if repeat
        { errors: errors, easy_attendance: entity } #.merge(easy_attendances: entities)
      end
    end
  end
end
