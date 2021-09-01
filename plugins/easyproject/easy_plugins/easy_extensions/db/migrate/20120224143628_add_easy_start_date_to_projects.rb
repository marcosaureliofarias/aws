class AddEasyStartDateToProjects < ActiveRecord::Migration[4.2]
  def self.up
    add_column :projects, :easy_start_date, :date
  end

  def self.down
    remove_column :projects, :easy_start_date
  end
end