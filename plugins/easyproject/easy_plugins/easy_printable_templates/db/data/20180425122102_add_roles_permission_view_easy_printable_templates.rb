class AddRolesPermissionViewEasyPrintableTemplates < ActiveRecord::Migration[4.2]
  def self.up
    Role.givable.each do |role|
      role.add_permission!(:view_easy_printable_templates) unless role.permissions.include?(:view_easy_printable_templates)
      role.add_permission!(:manage_easy_printable_templates) unless role.permissions.include?(:manage_easy_printable_templates)
    end
  end

  def self.down
  end
end
