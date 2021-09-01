class CreateEasyRolesTrackers < ActiveRecord::Migration[5.2]
  def change
    create_table :easy_role_tracker_restrictions, primary_key: %i[role_id tracker_id] do |t|
      t.belongs_to :role
      t.belongs_to :tracker
    end
  end

end
