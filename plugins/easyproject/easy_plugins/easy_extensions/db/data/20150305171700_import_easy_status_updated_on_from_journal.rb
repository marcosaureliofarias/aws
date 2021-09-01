class ImportEasyStatusUpdatedOnFromJournal < EasyExtensions::EasyDataMigration
  def self.up
    tmp = Journal.joins(:details).
        where(:journals => { :journalized_type => 'Issue' }, :journal_details => { :prop_key => 'status_id' }).
        order("#{Journal.table_name}.created_on ASC").
        select([:journalized_id, "#{Journal.table_name}.created_on"]).inject({}) do |mem, var|
      mem[var.journalized_id] = var.created_on
      mem
    end

    Issue.on_active_project.where(:easy_status_updated_on => nil).find_each(:batch_size => 50) do |issue|
      easy_status_updated_on = tmp[issue.id] || issue.created_on
      issue.update_column(:easy_status_updated_on, easy_status_updated_on)
    end
  end

  def self.down
    Issue.update_all(:easy_status_updated_on => nil)
  end
end
