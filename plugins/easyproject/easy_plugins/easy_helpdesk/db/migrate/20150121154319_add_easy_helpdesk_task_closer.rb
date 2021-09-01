class AddEasyHelpdeskTaskCloser < ActiveRecord::Migration[4.2]
  def up
    change_table(EasyHelpdeskProject.table_name) do |t|
      t.boolean(:automatically_issue_closer_enable, :default => false)
    end
  end

  def down
    change_table(EasyHelpdeskProject.table_name) do |t|
      t.remove(:automatically_issue_closer_enable)
    end
  end
end
