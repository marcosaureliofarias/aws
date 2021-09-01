class CreateEasyActionSequenceInstances < ActiveRecord::Migration[5.2]

  def up
    create_table :easy_action_sequence_instances, force: true do |t|
      t.belongs_to :easy_action_sequence, null: false, index: { name: 'idx_easi_1_20190926' }
      t.belongs_to :current_easy_action_state, null: false, index: { name: 'idx_easi_2_20190926' }
      t.belongs_to :entity, null: false, polymorphic: true, index: { name: 'idx_easi_3_20190926' }

      t.integer :status, null: false, default: 0, index: { name: 'idx_easi_4_20190926' }

      t.text :settings, null: true

      t.timestamps null: false
    end
  end

  def down
    drop_table :easy_action_sequence_instances
  end

end
