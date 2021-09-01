class ImportClosedByFromJournal < EasyExtensions::EasyDataMigration
  def self.up
    statuses = IssueStatus.where(:is_closed => true).pluck(:id).map(&:to_s)
    tmp      = Journal.joins(:details).where(:journals => { :journalized_type => 'Issue' }, :journal_details => { :prop_key => 'status_id', :value => statuses }).order("#{Journal.table_name}.created_on ASC").select([:journalized_id, :user_id, "#{Journal.table_name}.created_on"]).distinct.inject(Hash.new { |hash, key| hash[key] = Array.new }) do |mem, var|
      mem[var.user_id] << var.journalized_id
      mem
    end
    tmp.each do |user_id, issue_ids|
      Issue.where(:id => issue_ids).update_all(:easy_closed_by_id => user_id)
    end

  end

  def self.down
    Issue.update_all(:easy_closed_by_id => nil)
  end
end
