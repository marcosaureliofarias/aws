class CalculateEasyLevelForIssues < ActiveRecord::Migration[4.2]
  def self.up
    Issue.reset_column_information

    Issue.find_each(batch_size: 100) do |issue|
      issue.update_column(:easy_level, issue.level)
    end
  end

  def self.down
    # Issue.update_all(easy_level: nil) # Previous migration drop this column, in uninstall process this useless
  end
end
