class AddPermissionToRoles < ActiveRecord::Migration[4.2]
  def self.up
    Role.where(:builtin => 0).each do |role|
      role.permissions ||= []
      role.permissions << :manage_my_page unless role.permissions.include?(:manage_my_page)
      role.save!
    end
  end

  def self.down
  end
end
