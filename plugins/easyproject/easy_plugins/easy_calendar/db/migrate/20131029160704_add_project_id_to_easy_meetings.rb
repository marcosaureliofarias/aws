class AddProjectIdToEasyMeetings < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_meetings, :project_id, :integer
  end
end
