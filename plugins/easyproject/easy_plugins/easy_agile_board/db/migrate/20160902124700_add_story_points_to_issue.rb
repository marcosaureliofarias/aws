class AddStoryPointsToIssue < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :easy_story_points, :integer, default: 0
  end
end
