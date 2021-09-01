class AddEasyPagesDescription < ActiveRecord::Migration[5.2]
  def change
    add_column :easy_pages, :description, :text, :after => :user_defined_name
    EasyPage.reset_column_information
  end
end
