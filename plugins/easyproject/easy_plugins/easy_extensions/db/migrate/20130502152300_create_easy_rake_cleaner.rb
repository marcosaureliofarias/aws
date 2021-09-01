class CreateEasyRakeCleaner < ActiveRecord::Migration[4.2]

  def self.up
    t         = EasyRakeTaskHistoryCleaner.new(:active => true, :settings => {}, :period => :daily, :interval => 1, :next_run_at => Time.now.beginning_of_day)
    t.builtin = 1
    t.save!
  end

  def self.down
    # EasyRakeTaskHistoryCleaner.destroy_all # this should be in data migration
  end

end
