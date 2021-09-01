class CreateEasyRakeTaskReceiveMail < ActiveRecord::Migration[4.2]

  def self.up
    EasyRakeTaskEasyHelpdeskReceiveMail.reset_column_information

    t = EasyRakeTaskEasyHelpdeskReceiveMail.new(:active => true, :settings => {'pop3' => {}, 'imap' => {}}, :period => :minutes, :interval => 5, :next_run_at => Time.now)
    t.builtin = 1
    t.save!
  end

  def self.down
    EasyRakeTaskEasyHelpdeskReceiveMail.reset_column_information
    EasyRakeTaskEasyHelpdeskReceiveMail.all.each do |e|
      e.easy_rake_task_infos.destroy_all
    end
    EasyRakeTaskEasyHelpdeskReceiveMail.delete_all
  end
end