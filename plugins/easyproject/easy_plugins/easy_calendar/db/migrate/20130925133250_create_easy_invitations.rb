class CreateEasyInvitations < ActiveRecord::Migration[4.2]
  def up
    unless ActiveRecord::Base.connection.table_exists?('easy_invitations')
      create_table :easy_invitations do |t|
        t.references :easy_meeting
        t.references :user
        t.boolean :accepted

        t.timestamps
      end
      add_index :easy_invitations, :easy_meeting_id
      add_index :easy_invitations, :user_id
    end
  end

  def down
    drop_table :easy_invitations
  end
end
