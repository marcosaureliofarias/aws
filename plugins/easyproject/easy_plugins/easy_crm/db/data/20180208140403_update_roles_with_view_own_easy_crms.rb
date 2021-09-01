class UpdateRolesWithViewOwnEasyCrms < ActiveRecord::Migration[4.2]
  def self.up
    role_ids = []
    Role.all.each do |role|
      if role.permissions.include?(:view_own_easy_crms) && !role.permissions.include?(:view_easy_crms)
        role_ids << role.id
        role.add_permission!(:view_easy_crms)
      end
    end

    Role.where(id: role_ids).update_all(easy_crm_cases_visibility: 'own')
  end

  def self.down
  end
end
