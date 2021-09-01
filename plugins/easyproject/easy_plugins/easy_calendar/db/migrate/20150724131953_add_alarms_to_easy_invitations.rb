class AddAlarmsToEasyInvitations < ActiveRecord::Migration[4.2]
  def up
    if !column_exists?(:easy_invitations, :alarms)
      adapter_name = ActiveRecord::Base.connection_config[:adapter]
      case adapter_name.downcase
      when /(mysql|mariadb)/
        add_column :easy_invitations, :alarms, :text, limit: 4294967295
      else
        add_column :easy_invitations, :alarms, :text
      end
    end

    EasyInvitation.reset_column_information
    EasyInvitation.find_each(batch_size: 50) do |invitation|
      invitation.skip_notifications = true
      invitation.__send__(:set_alarms)
      invitation.save
    end
  end

  def down
    remove_column :easy_invitations, :alarms
  end
end
