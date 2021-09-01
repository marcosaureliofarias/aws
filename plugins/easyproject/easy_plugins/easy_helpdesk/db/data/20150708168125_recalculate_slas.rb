class RecalculateSlas < EasyExtensions::EasyDataMigration
  def self.up
    Issue.open.includes(:project => {:easy_helpdesk_project => :easy_helpdesk_project_sla}).
      where.not(:easy_helpdesk_projects => {:id => nil}).find_each(:batch_size => 50) do |i|
      i.ensure_correct_sla_data(true)
      i.update_columns({:easy_due_date_time => i.easy_due_date_time,
       :easy_response_date_time => i.easy_response_date_time,
       :easy_helpdesk_project_sla_id => i.easy_helpdesk_project_sla_id})
    end unless Redmine::Plugin.disabled?(:easy_helpdesk)
  end

  def self.down
  end
end
