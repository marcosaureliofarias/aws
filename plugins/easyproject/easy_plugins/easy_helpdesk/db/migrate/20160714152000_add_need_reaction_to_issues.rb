class AddNeedReactionToIssues < ActiveRecord::Migration[4.2]

  def change
    add_column :issues, :easy_helpdesk_need_reaction, :boolean, {:default => false, :null => false}
  end

end
