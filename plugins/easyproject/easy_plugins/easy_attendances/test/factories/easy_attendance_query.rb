FactoryBot.define do
  factory :easy_attendance_query, parent: :easy_query, class: 'EasyAttendanceQuery'
  factory :easy_attendance_user_query, parent: :easy_query, class: 'EasyAttendanceUserQuery'
end
