class CreateEasyRakeTaskEasyHelpdeskIssueCloserAutomat < ActiveRecord::Migration[4.2]
  def up
    t = EasyRakeTaskEasyHelpdeskIssueCloserAutomat.new(:active => true, :settings => {}, :period => :hourly, :interval => 1, :next_run_at => Time.now)
    t.builtin = 1
    t.save!
  end

  def down
    EasyRakeTaskEasyHelpdeskIssueCloserAutomat.destroy_all
  end
end
