class RebuildIssueCategories < ActiveRecord::Migration[4.2]
  def self.up
    IssueCategory.rebuild! if IssueCategory.count > 0
  end

  def self.down
  end
end
