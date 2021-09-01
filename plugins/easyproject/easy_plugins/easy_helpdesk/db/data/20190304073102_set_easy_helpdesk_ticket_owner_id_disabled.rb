class SetEasyHelpdeskTicketOwnerIdDisabled < EasyExtensions::EasyDataMigration
  def up
    Tracker.all.each do |tracker|
      tracker.core_fields = tracker.core_fields - ['easy_helpdesk_ticket_owner_id']
      tracker.save(validate: false)
    end
  end

  def down
  end
end
