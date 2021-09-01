class CreateEasyActionChecks < ActiveRecord::Migration[5.2]

  def up
    create_table :easy_action_check_templates, force: true do |t|
      t.string :name, null: false

      t.string :action_class, null: false
      t.text :action_settings, null: true

      t.timestamps null: false
    end

    create_table :easy_action_checks, force: true do |t|
      t.belongs_to :easy_action_check_template, null: false,  index: { name: 'idx_eac_1_202002' }
      t.belongs_to :entity, polymorphic: true, null: false

      t.integer :status, null: false, default: 0
      t.text :result, null: true

      t.timestamps null: false
    end

  end

  def down
    drop_table :easy_action_checks
    drop_table :easy_action_check_templates
  end

end
