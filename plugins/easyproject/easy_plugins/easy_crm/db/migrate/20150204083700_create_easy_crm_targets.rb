class CreateEasyCrmTargets < ActiveRecord::Migration[4.2]
  def self.up

    create_table :easy_crm_targets, :force => true do |t|
      t.column :user_id, :integer, {:null => false}
      t.column :project_id, :integer, {:null => false}
      t.column :target, :decimal, {:null => false, :precision => 30, :scale => 2}
      t.column :valid_from, :datetime, {:null => false}
      t.column :valid_to, :datetime, {:null => false}
      t.timestamps
    end

  end

  def self.down
    drop_table :easy_crm_targets
  end

end
