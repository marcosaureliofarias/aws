module EasySwagger
  class EasyAttendanceWithoutFactorizedAttendances
    include EasySwagger::BaseModel
    swagger_me(entity: 'EasyAttendance')

    def self.attendance_schema
      shared_scheme do
        relation 'user'

        property 'arrival', type: 'string' do
          key :example, '2020-12-03T00:00:00Z'
          key :description, ''
          key :format, 'datetime'
        end

        property 'departure', type: 'string' do
          key :example, '2020-12-03T23:30:00Z'
          key :description, ''
          key :format, 'datetime'
        end

        relation 'edited_by'

        property 'edited_when', type: 'string' do
          key :description, ''
          key :format, 'datetime'
        end

        property 'locked', type: 'boolean'

        timestamps

        property 'arrival_user_ip', type: 'string', if: -> (entity) { ::User.current.allowed_to?(:view_easy_attendances_extra_info, nil, global: true) } do
          key :example, '79.98.112.115'
          key :format, 'ipv4'
          key :readOnly, true
        end

        relation 'time_entry'

        property 'departure_user_ip', type: 'string', if: -> (entity) { ::User.current.allowed_to?(:view_easy_attendances_extra_info, nil, global: true) } do
          key :example, '79.98.112.115'
          key :format, 'ipv4'
          key :readOnly, true
        end

        property 'range' do
          key :enum, [::EasyAttendance::RANGE_FULL_DAY, ::EasyAttendance::RANGE_FORENOON, ::EasyAttendance::RANGE_AFTERNOON]
        end

        property 'description', type: 'string'

        property 'approval_status' do
          key :enum, [::EasyAttendance::APPROVAL_WAITING, ::EasyAttendance::APPROVAL_APPROVED, ::EasyAttendance::APPROVAL_REJECTED, ::EasyAttendance::CANCEL_WAITING, ::EasyAttendance::CANCEL_APPROVED, ::EasyAttendance::CANCEL_REJECTED]
          key :readOnly, true
        end

        relation 'approved_by'

        property 'approved_at', type: 'string' do
          key :description, ''
          key :format, 'datetime'
          key :readOnly, true
        end

        property 'previous_approval_status', type: 'boolean'

        property 'arrival_latitude', type: 'number' do
          key :example, '50.04'
          key :format, 'float'
          key :readOnly, true
        end

        property 'arrival_longitude', type: 'number' do
          key :example, '14.98'
          key :format, 'float'
          key :readOnly, true
        end

        property 'departure_latitude', type: 'number' do
          key :example, '50.04'
          key :format, 'float'
          key :readOnly, true
        end

        property 'departure_longitude', type: 'number' do
          key :example, '14.98'
          key :format, 'float'
          key :readOnly, true
        end

        property 'time_zone', type: 'string'

        property 'easy_external_id', type: 'string' do
          key :example, '1919385b-5040-46e7-93e5-addbab6b39fa'
          key :format, 'uuid'
        end

        property 'need_approve', type: 'boolean', value: ->(context, entity) { entity.need_approve? } do
          key :readOnly, true
        end

        property 'limit_exceeded', type: 'boolean', value: ->(context, entity) { !entity.easy_attendance_vacation_limit_valid? } do
          key :readOnly, true
        end

        property 'hours', type: 'number' do
          key :example, '23.5'
          key :format, 'float'
          key :readOnly, true
        end
      end
    end

    shared_scheme &EasySwagger::EasyAttendanceWithoutFactorizedAttendances.attendance_schema

    response_schema do
      property 'easy_attendance_activity', type: 'object' do
        key "$ref", ::EasySwagger::EasyAttendanceActivity.response_schema_name
      end
    end
  end
end