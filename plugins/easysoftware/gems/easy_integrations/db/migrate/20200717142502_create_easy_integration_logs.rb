class CreateEasyIntegrationLogs < ActiveRecord::Migration[5.2]

  def up
    create_table :easy_integration_logs, force: true do |t|
      t.belongs_to :easy_integration, null: false, index: true

      t.belongs_to :entity, polymorphic: true, null: false, index: true
      t.integer :status, null: false, default: 0
      t.string :action, null: false
      t.text :return_value

      t.timestamps null: false
      t.index [:easy_integration_id, :entity_id], name: "idx_eil_integration_entity"
    end

  end

  def down
    drop_table :easy_integration_logs
  end

end
