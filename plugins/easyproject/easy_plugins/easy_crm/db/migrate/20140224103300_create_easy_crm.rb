class CreateEasyCrm < ActiveRecord::Migration[4.2]
  def self.up

    create_table :easy_crm_case_statuses, force: true do |t|
      t.column :name, :string, null: false, limit: 255
      t.column :internal_name, :string, null: true, limit: 255
      t.column :position, :integer, null: true, default: 1
      t.column :is_default, :boolean, null: false, default: false
      t.timestamps
    end
    add_index :easy_crm_case_statuses, [:internal_name], name: 'idx_easy_crm_case_statuses_1'

    create_table :easy_crm_cases, force: true do |t|
      t.column :name, :string, null: false, limit: 255
      t.column :description, :text, null: true
      t.column :author_id, :integer, null: false
      t.column :project_id, :integer, null: false
      t.column :assigned_to_id, :integer, null: true
      t.column :easy_crm_case_status_id, :integer, null: false
      t.column :due_date, :date, null: true
      t.column :email, :string, null: true, limit: 2048
      t.column :telephone, :string, null: true, limit: 255
      t.column :price, :decimal, null: true, precision: 30, scale: 2
      t.column :currency, :string, null: true, limit: 255, default: 'EUR'
      t.timestamps
    end
    add_index :easy_crm_cases, [:author_id], name: 'idx_easy_crm_cases_1'
    add_index :easy_crm_cases, [:project_id], name: 'idx_easy_crm_cases_2'
    add_index :easy_crm_cases, [:assigned_to_id], name: 'idx_easy_crm_cases_3'
    add_index :easy_crm_cases, [:easy_crm_case_status_id], name: 'idx_easy_crm_cases_4'
    add_index :easy_crm_cases, [:due_date], name: 'idx_easy_crm_cases_5'

    create_table :easy_crm_cases_issues, primary_key: %i[easy_crm_case_id issue_id] do |t|
      t.belongs_to :easy_crm_case
      t.belongs_to :issue
    end

  end

  def self.down
    drop_table :easy_crm_cases_issues
    drop_table :easy_crm_cases
    drop_table :easy_crm_case_statuses
  end

end
