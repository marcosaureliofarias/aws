class AddUseEasyAttendancesPermissionToViewPermittedUsers < ActiveRecord::Migration[4.2]
  def up
    Role.remove_validation :name
    Role.all.each { |role| role.add_permission! :use_easy_attendances if role.permissions.include? :view_easy_attendances }
  end
end
