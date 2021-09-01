class CreateEasyActionStates < ActiveRecord::Migration[5.2]

  def up
    create_table :easy_action_states, force: true do |t|
      t.belongs_to :easy_action_sequence_template, null: false

      t.string :name, null: false

      t.boolean :initial, null: false, default: false, index: true
    end
  end

  def down
    drop_table :easy_action_states
  end

end
