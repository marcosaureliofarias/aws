class CreateEasyCalculationSettings < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create!(:name => 'calculation', :value => {
      :tracker_ids => Tracker.pluck(:id)
    })
  end

  def self.down
    EasySetting.where(:name => 'calculation').destroy_all
  end
end
