class CreateOneTimeJobs < ActiveRecord::Migration[4.2]

  def self.up

    add_column :easy_rake_task_infos, :options, :text, { :null => true }
    add_column :easy_rake_task_infos, :method_to_execute, :string, { :null => true }

    adapter_name = Issue.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      change_column :easy_rake_task_infos, :options, :text, { :limit => 4294967295, :default => nil }
    end

    t         = OneTimeEasyRakeTask.new(:active => true, :settings => {}, :period => :minutes, :interval => 1, :next_run_at => Time.now.beginning_of_day)
    t.builtin = 1
    t.save!
  end

  def self.down

    OneTimeEasyRakeTask.destroy_all

    remove_column :easy_rake_task_infos, :options
    remove_column :easy_rake_task_infos, :method_to_execute

  end

end
