class CreateReGoals < ActiveRecord::Migration[4.2]
  def self.up
    create_table :re_goals do |t|
      end
  end

  def self.down
    drop_table :re_goals
  end
end
