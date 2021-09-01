class AddEasyIsTemplateAndStatusIndexesToProjects < ActiveRecord::Migration[4.2]
  def self.up
    add_index :projects, :easy_is_easy_template
    add_index :projects, :status
  end

  def self.down
    remove_index :projects, :easy_is_easy_template
    remove_index :projects, :status
  end
end
