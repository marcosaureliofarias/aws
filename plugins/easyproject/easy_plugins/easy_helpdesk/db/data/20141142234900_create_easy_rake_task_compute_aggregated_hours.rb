class CreateEasyRakeTaskComputeAggregatedHours < EasyExtensions::EasyDataMigration

  def self.up
    t = EasyRakeTaskComputeAggregatedHours.new(:active => true, :settings => {}, :period => :daily, :interval => 1, :next_run_at => Time.now.beginning_of_day)
    t.builtin = 1
    t.save!
  end

  def self.down
    EasyRakeTaskComputeAggregatedHours.destroy_all
  end

end