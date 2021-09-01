class CreateEasyActionStateActions < ActiveRecord::Migration[5.2]

  def up
    create_table :easy_action_state_actions, force: true do |t|
      t.belongs_to :easy_action_sequence_template, null: false, index: { name: 'idx_easa_1_20190926' }
      t.belongs_to :easy_action_state, null: false

      t.string :name, null: false

      t.string :action_class, null: false
      t.text :action_settings, null: true

      t.timestamps null: false
    end
  end

  def down
    drop_table :easy_action_state_actions
  end

end
