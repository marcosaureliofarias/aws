class MigrateEasyResponseTime < EasyExtensions::EasyDataMigration
  def self.up
    t = Issue.arel_table
    EasyHelpdeskProjectSla.joins(:issues).preload(:issues).where(t[:easy_helpdesk_mailbox_username].not_eq(nil)).find_each(:batch_size => 50) do |sla|
      sla.issues.where(t[:easy_helpdesk_mailbox_username].not_eq(nil)).find_each(:batch_size => 50) do |i|
        response_time = i.created_on + sla.hours_to_response.hours
        i.update_column(:easy_response_date_time, response_time) if i.easy_response_date_time != response_time
      end
    end

  end

  def self.down
  end
end
