module EasyGraphql
  module Mutations
    class EasyAttendanceValidator < Base
      description 'Expect all EasyAttendance attributes for new record.
                   Expect changed EasyAttendance attributes for edit record.
                   Return error object with validation messages.'

      argument :id, ID, required: false
      argument :user_ids, [ID], required: false
      argument :attributes, GraphQL::Types::JSON, required: true

      field :easy_attendance, Types::EasyAttendance, null: true
      field :errors, [Types::EasyAttendanceError], null: true

      attr_accessor :entities
      # EasyAttendanceValidator(attributes:{}) - for preselect form
      # EasyAttendanceValidator(user_ids: [1,2], attributes:{arrival: '', departure: '' ...}) - for validate form; multiple attendance
      # EasyAttendanceValidator(attributes:{user_id: 1, arrival: '', departure: '' ...}) - for validate form; single attendance

      def resolve(attributes:, id: nil, user_ids: nil)
        # Convert `Hash` to with  indifferent access
        unless attributes.is_a?(ActionController::Parameters)
          attributes = attributes.with_indifferent_access
        end
        user_ids ||= [attributes['user_id']]
        self.entities = prepare_easy_attendances(id, user_ids)
        errors = []
        entities.each do |record|
          self.entity = record
          entity.safe_attributes = attributes.except('user_id')
          entity.non_work_start_time = attributes['non_work_start_time'] #should be setted after arrival
          entity.assign_default_activity
          entity.set_default_range
          user = entity.user
          if entity.can_edit?
            entity.ensure_easy_attendance_non_work_activity
            ensure_faktorized_attendances
            if entity.errors.any? || entity.invalid?
              errors += prepare_errors.each {|error| error[:user] = user }
            end
          else
            errors << { attribute: 'base', full_messages: [I18n.t('easy_graphql.not_authorized')], user: user }
          end
        end

        # easy_attendance is last record in array if multiple
        # easy_attendance is first working day attendance if repeat
        { errors: errors.uniq, easy_attendance: entity }
      end

      private

      def prepare_easy_attendances(id, user_ids)
        if id
          ::EasyAttendance.visible.where(id: id)
        else
          Array.wrap(user_ids).uniq.map do |user_id|
            ::EasyAttendance.new(user_id: user_id)
          end
        end
      end

      def ensure_faktorized_attendances
        original_dates = { arrival: entity.arrival, departure: entity.departure }
        entity.ensure_faktorized_attendances
        entity.safe_attributes = original_dates
      end

    end
  end
end
