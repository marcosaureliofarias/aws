class AddCalculationDateToProjects < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :calculation_date, :date
  end
end
