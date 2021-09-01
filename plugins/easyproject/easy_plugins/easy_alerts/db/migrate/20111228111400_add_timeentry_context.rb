class AddTimeentryContext < ActiveRecord::Migration[4.2]

  def self.up
    AlertContext.create :name => 'timeentry'
  end

  def self.down
  end
end