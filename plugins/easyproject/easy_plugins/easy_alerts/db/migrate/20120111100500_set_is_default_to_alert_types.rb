class SetIsDefaultToAlertTypes < ActiveRecord::Migration[4.2]

  def self.up
    AlertType.reset_column_information
    
    AlertType.where(:name => 'notice').update_all(:is_default => true)
  end

  def self.down
  end
end