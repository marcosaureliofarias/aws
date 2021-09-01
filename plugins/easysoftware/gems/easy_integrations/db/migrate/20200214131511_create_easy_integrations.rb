class CreateEasyIntegrations < ActiveRecord::Migration[5.2]
  MYSQL_TEXT_LIMIT = 4294967295

  def up
    create_table :easy_integrations, force: true do |t|
      t.string :name, null: false
      t.string :metadata_klass, null: false
      t.json :metadata_settings, null: false
      t.string :service_klass, null: false
      t.string :entity_klass, null: false, index: true
      t.boolean :active, null: false, default: true, index: true
      t.boolean :perform_once, null: false, default: true
      t.boolean :on_create, null: false, default: true, index: true
      t.boolean :on_update, null: false, default: false, index: true
      t.boolean :on_destroy, null: false, default: false, index: true
      t.boolean :on_time, null: false, default: false, index: true
      t.boolean :use_query, null: false, default: false
      t.json :query_settings, null: true
      t.integer :execute_as_user_id, null: true
      t.boolean :use_journal, null: false, default: false
      t.boolean :grouped_notify, null: false, default: false
      t.string :cron_expr, null: true
      t.datetime :next_run_at, null: true, index: true
      t.belongs_to :easy_oauth2_client_application, null: true

      t.timestamps null: false
    end
  end

  def down
    drop_table :easy_integrations
  end

end
