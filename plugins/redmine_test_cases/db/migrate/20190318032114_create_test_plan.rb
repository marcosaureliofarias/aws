class CreateTestPlan < ActiveRecord::Migration[5.2]
  def change
    create_table :test_plans do |t|
      t.string :name, null: false
      t.references :project, null: false
      t.references :author, null: false

      t.timestamps null: false
    end
  end
end
