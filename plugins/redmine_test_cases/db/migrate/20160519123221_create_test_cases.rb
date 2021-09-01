class CreateTestCases < ActiveRecord::Migration[4.2]
  def change
    create_table :test_cases, force: true do |t|
      t.string :name, null: true
      t.text :scenario, null: true
      t.text :expected_result, null: true
      t.references :project, null: false
      t.references :author, null: false
      t.string :easy_external_id, null: true

      t.timestamps null: false
    end
  end
end
