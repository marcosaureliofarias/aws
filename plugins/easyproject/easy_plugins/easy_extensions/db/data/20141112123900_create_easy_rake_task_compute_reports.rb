class CreateEasyRakeTaskComputeReports < ActiveRecord::Migration[4.2]

  def self.up
    t         = EasyRakeTaskComputeReports.new(:active => true, :settings => {}, :period => :daily, :interval => 1, :next_run_at => Time.now.beginning_of_day)
    t.builtin = 1
    t.save!
  end

  def self.down
    EasyRakeTaskComputeReports.destroy_all
  end

end