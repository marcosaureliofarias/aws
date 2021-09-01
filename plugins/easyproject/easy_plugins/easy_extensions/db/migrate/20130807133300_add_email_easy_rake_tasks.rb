class AddEmailEasyRakeTasks < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_rake_tasks, :failure_mail, :string, { :null => true }
  end

  def self.down
    remove_column :easy_rake_tasks, :failure_mail
  end

end