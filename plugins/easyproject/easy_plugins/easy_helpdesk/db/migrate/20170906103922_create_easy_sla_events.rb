class CreateEasySlaEvents < ActiveRecord::Migration[4.2]
  def up
    return if table_exists?(:easy_sla_events)

    create_table :easy_sla_events, force: true do |t|
      t.string :name, null: true
      t.datetime :occurence_time, null: true, index: true
      t.references :issue, index: true
      t.references :user, index: true
      t.datetime :sla_response, null: true, index: true
      t.datetime :sla_resolve, null: true, index: true
      t.float :first_response, null: true, index: true
      t.float :sla_response_fulfilment, null: true
      t.float :sla_resolve_fulfilment, null: true
      t.references :project, index: true
      t.timestamps null: false
    end
  end

  def down
    return unless table_exists?(:easy_sla_events)

    drop_table :easy_sla_events
  end
end
