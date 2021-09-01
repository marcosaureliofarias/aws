class FillEntityToTimeEntries < ActiveRecord::Migration[4.2]
  def up
    t = TimeEntry.arel_table
    TimeEntry.where(t[:issue_id].not_eq(nil)).update_all(["entity_type = ?, entity_id = #{TimeEntry.quoted_table_name}.issue_id", 'Issue'])
    TimeEntry.where(:issue_id => nil).update_all(["entity_type = ?, entity_id = #{TimeEntry.quoted_table_name}.project_id", 'Project'])
  end

  def down

  end
end
