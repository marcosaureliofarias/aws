class CreateNewsUsers < ActiveRecord::Migration[4.2]

  def self.up
    create_table :news_users, :id => false do |t|
      t.column :user_id, :integer, { :null => false }
      t.column :news_id, :integer, { :null => false }
    end
  end

  def self.down
    drop_table :news_users if table_exists?(:news_users)
  end
end
