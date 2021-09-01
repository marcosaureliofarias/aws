class AddUsersDescription < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :description, :text, :after => :lastname
    User.reset_column_information
  end
end
