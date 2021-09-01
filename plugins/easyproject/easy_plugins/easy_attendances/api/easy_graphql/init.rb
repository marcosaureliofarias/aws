# frozen_string_literal: true

EasyGraphql.patch('EasyGraphql::Types::Query') do
  field :easy_attendance, EasyGraphql::Types::EasyAttendance, null: true do
    description 'Find an EasyAttendance by ID'
    argument :id, GraphQL::Types::ID, required: true
  end

  field :easy_attendances_approval, resolver: EasyGraphql::Resolvers::EasyAttendancesApproval

  def easy_attendance(id:)
    ::EasyAttendance.visible.find_by(id: id)
  end

end

EasyGraphql.patch('EasyGraphql::Types::Mutation') do
  field :easy_attendance_update, mutation: EasyGraphql::Mutations::EasyAttendanceUpdate
  field :easy_attendance_create, mutation: EasyGraphql::Mutations::EasyAttendanceCreate
  field :easy_attendance_validator, mutation: EasyGraphql::Mutations::EasyAttendanceValidator
end
