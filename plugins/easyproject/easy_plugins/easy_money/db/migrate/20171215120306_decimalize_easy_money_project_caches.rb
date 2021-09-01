class DecimalizeEasyMoneyProjectCaches < ActiveRecord::Migration[4.2]
  def up
    EasyMoneyProjectCache.reset_column_information
    EasyMoneyProjectCache.columns.select{|x| x.type == :float}.map(&:name).each do |cname|
      change_column :easy_money_project_caches, cname, :decimal, { null: false, precision: 60, scale: 2, default: 0.0}
    end
  end

  def down
  end
end