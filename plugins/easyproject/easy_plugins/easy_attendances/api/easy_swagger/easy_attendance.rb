module EasySwagger
  class EasyAttendance
    include EasySwagger::BaseModel
    swagger_me

    shared_scheme &EasySwagger::EasyAttendanceWithoutFactorizedAttendances.attendance_schema

    request_schema do
      relation 'easy_attendance_activity'

      key :required, %w[user_id arrival easy_entity_activity_id]
    end

    response_schema do
      property 'easy_attendance_activity', type: 'object' do
        key "$ref", ::EasySwagger::EasyAttendanceActivity.response_schema_name
      end

      property 'factorized_attendances', type: 'array', if: ->(entity) { entity.factorized_attendances.is_a?(Array) } do
        key :description, 'Factorized_attendances is array which contains attendance records for each day if the attendance is planned for longer than one day. If this attendance is a 14 day vacation, this array contains attendance (vacation) records for each working day in these 14 days.'
        key :xml, wrapped: true
        key :readOnly, true
        items ref: ::EasySwagger::EasyAttendanceWithoutFactorizedAttendances
      end
    end
  end
end
