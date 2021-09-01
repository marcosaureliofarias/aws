class AddEasyResourceDontAllocateToEasyMeetings < ActiveRecord::Migration[4.2]

  def up
    return if column_exists?(:easy_meetings, :easy_resource_dont_allocate)
    add_column :easy_meetings, :easy_resource_dont_allocate, :boolean, default: false
  end

  def down
    remove_column :easy_meetings, :easy_resource_dont_allocate
  end

end
