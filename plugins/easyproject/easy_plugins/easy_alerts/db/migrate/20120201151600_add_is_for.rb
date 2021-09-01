class AddIsFor < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_alerts, :is_for, :string, {:null => false, :default => 'only_me'}
  end

  def self.down
    remove_column :easy_alerts, :is_for
  end
  
end