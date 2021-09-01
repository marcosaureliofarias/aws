class ChagneEasyInvitationAlarmsToNewIcalendar < ActiveRecord::Migration[4.2]
  def up
    EasyInvitation.update_all(alarms: nil)
  end
end
