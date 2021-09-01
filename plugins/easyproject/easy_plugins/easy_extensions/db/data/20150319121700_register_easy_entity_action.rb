class RegisterEasyEntityAction < ActiveRecord::Migration[4.2]
  def self.up

    t         = EasyRakeTaskEasyEntityAction.new(:active => true, :settings => {}, :period => :hourly, :interval => 1, :next_run_at => Time.now.beginning_of_day)
    t.builtin = 1
    t.save!

  end

  def self.down

    EasyRakeTaskEasyEntityAction.destroy_all

  end

end
