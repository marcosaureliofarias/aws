class CreateEasyActionSequenceTemplates < ActiveRecord::Migration[5.2]

  def up
    create_table :easy_action_sequence_categories, force: true do |t|
      t.string :name, null: false
      t.text :description, null: true

      t.timestamps null: false
    end

    create_table :easy_action_sequence_templates, force: true do |t|
      t.string :name, null: false
      t.text :description, null: true
      t.belongs_to :easy_action_sequence_category, null: true, index: { name: 'idx_east_1_20191218' }

      t.string :target_entity_class, null: false, index: true
      t.string :condition_class, null: true
      t.text :condition_settings, null: true

      t.belongs_to :author, null: false
      t.timestamps null: false
    end
  end

  def down
    drop_table :easy_action_sequence_templates
    drop_table :easy_action_sequence_categories
  end

end
