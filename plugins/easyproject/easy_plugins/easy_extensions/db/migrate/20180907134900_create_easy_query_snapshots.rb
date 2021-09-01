class CreateEasyQuerySnapshots < ActiveRecord::Migration[4.2]

  def self.up

    create_table :easy_query_snapshots, force: true do |t|
      t.integer :easy_query_id, null: true, index: true
      t.string :epzm_uuid, null: true, limit: 36, index: true

      t.string :execute_as, null: false, default: 'author'
      t.integer :execute_as_user_id, null: true

      t.text :period_options, null: true
      t.text :settings, null: true

      t.datetime :last_executed, null: true
      t.datetime :nextrun_at, null: true, index: true

      t.integer :author_id, null: false
      t.timestamps null: false
    end

    create_table :easy_query_snapshot_data, force: true do |t|
      t.belongs_to :easy_query_snapshot

      t.date :date, null: false

      t.float :value1, null: true
      t.float :value2, null: true
      t.float :value3, null: true
      t.float :value4, null: true
      t.float :value5, null: true

      t.timestamps null: false
    end

    add_index :easy_query_snapshot_data, [:easy_query_snapshot_id, :date], name: 'idx_eqsd_1'

    EasyQuerySnapshot.reset_column_information
    adapter_name = EasyQuerySnapshot.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      change_column :easy_query_snapshots, 'period_options', :text, limit: 4294967295, default: nil
    end

  end

  def self.down
    drop_table :easy_query_snapshot_data
    drop_table :easy_query_snapshots
  end

end
