class AddEasyChecklist < ActiveRecord::Migration[5.2]
  def change
    create_table :easy_checklists do |t|
      t.string :name
      t.string :type
      t.belongs_to :author

      t.belongs_to :entity, polymorphic: true

      t.timestamps null: false

      t.index [:id, :type]
    end
    
    create_table :easy_checklist_items do |t|
      t.string :subject
      t.integer :position
      t.boolean :done, default: false
      t.belongs_to :author
      t.belongs_to :changed_by
      t.datetime :last_done_change

      t.belongs_to :easy_checklist

      t.timestamps null: false
    end

    create_table :projects_easy_checklists, primary_key: %i[project_id easy_checklist_id] do |t|
      t.belongs_to :easy_checklist
      t.belongs_to :project
    end
  end

end
