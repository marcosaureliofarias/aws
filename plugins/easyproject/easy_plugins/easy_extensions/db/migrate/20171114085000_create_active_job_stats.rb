class CreateActiveJobStats < ActiveRecord::Migration[4.2]
  def change

    create_table :easy_active_job_statistics, force: true do |t|
      t.string :name, null: false, index: { unique: true }

      t.datetime :planned_at, null: true
      t.datetime :started_at, null: true
      t.datetime :finished_at, null: true
      t.integer :duration, null: false, default: 0

      t.timestamps null: false
    end

  end
end
