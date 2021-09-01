class DropNewsUsers < ActiveRecord::Migration[4.2]
  def self.up
    drop_table :news_users
  end

  def self.down
  end
end
