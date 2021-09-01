class CreateReSubtasks < ActiveRecord::Migration[4.2]
  def self.up
    create_table :re_subtasks do |t|
      t.column :solution, :string
      t.column :sub_type, :integer
    end
  end

  def self.down
    drop_table :re_subtasks
  end
end
