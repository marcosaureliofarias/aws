class AddDiscountToProjects < ActiveRecord::Migration[4.2]
  def self.up
    add_column :projects, :calculation_discount, :integer
  end

  def self.down
    remove_column :projects, :calculation_discount
  end
end
