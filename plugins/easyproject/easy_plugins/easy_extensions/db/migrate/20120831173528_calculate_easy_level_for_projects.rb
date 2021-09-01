class CalculateEasyLevelForProjects < ActiveRecord::Migration[4.2]
  def self.up
    Project.reset_column_information

    Project.roots.each do |project|
      # plugins/easyproject/easy_plugins/easy_extensions/lib/easy_patch/redmine/others/nested_set_traversing_patch.rb:54
      project.send(:set_easy_level)
    end
  end

  def self.down
    Project.update_all(:easy_level => nil)
  end
end
