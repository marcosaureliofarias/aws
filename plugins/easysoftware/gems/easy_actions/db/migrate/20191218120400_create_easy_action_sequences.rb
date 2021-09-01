class CreateEasyActionSequences < ActiveRecord::Migration[5.2]

  def up
    create_table :easy_action_sequences, force: true do |t|
      t.belongs_to :easy_action_sequence_template, null: false, index: true

      t.belongs_to :entity, null: false, polymorphic: true, index: { name: 'idx_eas_1_20191218' }

      t.belongs_to :author, null: false
      t.timestamps null: false
    end
  end

  def down
    drop_table :easy_action_sequences
  end

end
