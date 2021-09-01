class CreateEasyOrgChartNodes < ActiveRecord::Migration[4.2]
  def change
    create_table :easy_org_chart_nodes do |t|
      t.belongs_to :user, index: true
      t.integer :parent_id, :root_id, :lft, :rgt
      t.timestamps null: false
    end

    add_index :easy_org_chart_nodes, :lft
    # add_index :easy_org_chart_nodes, column: [:root_id, :lft, :rgt]
  end
end
