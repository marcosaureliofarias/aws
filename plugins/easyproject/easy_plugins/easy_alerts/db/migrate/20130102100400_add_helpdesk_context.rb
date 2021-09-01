class AddHelpdeskContext < ActiveRecord::Migration[4.2]

  def self.up
    AlertContext.create :name => 'helpdesk'
  end

  def self.down
  end
end