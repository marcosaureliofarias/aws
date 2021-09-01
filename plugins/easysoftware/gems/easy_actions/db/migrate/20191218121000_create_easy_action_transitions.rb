class CreateEasyActionTransitions < ActiveRecord::Migration[5.2]

  def up
    create_table :easy_action_transitions, force: true do |t|
      t.belongs_to :easy_action_sequence_template, null: false, index: { name: 'idx_eat_3_20190926' }

      t.string :name, null: false

      t.belongs_to :state_from, null: false, index: { name: 'idx_eat_1_20190926' }
      t.belongs_to :state_to, null: false, index: { name: 'idx_eat_2_20190926' }

      t.string :condition_class, null: false
      t.text :condition_settings, null: true

      t.timestamps null: false
    end
  end

  def down
    drop_table :easy_action_transitions
  end

end
