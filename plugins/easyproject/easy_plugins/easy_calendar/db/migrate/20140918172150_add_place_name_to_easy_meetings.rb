class AddPlaceNameToEasyMeetings < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_meetings, :place_name, :string, :default => nil
  end
end
