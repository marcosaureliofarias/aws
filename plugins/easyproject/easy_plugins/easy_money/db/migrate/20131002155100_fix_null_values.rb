class FixNullValues < ActiveRecord::Migration[4.2]
  def self.up
    EasyMoneySettings.where('project_id IS NOT NULL AND value IS NULL').delete_all
  end

  def self.down
  end
end