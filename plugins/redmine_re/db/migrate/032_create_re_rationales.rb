class CreateReRationales < ActiveRecord::Migration[4.2]
  def self.up
    create_table :re_rationales do |t|
    end
  end

  def self.down
    drop_table :re_rationales
  end
end
