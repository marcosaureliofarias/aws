class CreateReStatuses < ActiveRecord::Migration[4.2]
  def change
    create_table :re_statuses do |t|
      t.belongs_to :project
      t.string :label
      t.string :alias_name
      t.string :color
      t.boolean :in_use
      t.timestamps null: false
    end
  end
end