class AddTitleToEasyCalculations < ActiveRecord::Migration[4.2]
  def up
    add_column(:easy_calculations, :title, :string, { :null => true, :limit => 255 })
  end

  def down
    remove_column(:easy_calculations, :title)
  end
end
