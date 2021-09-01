class ChangeDefaultPositionToNullForEasyPrintableTemplatePage < ActiveRecord::Migration[4.2]
  def up
    change_column :easy_printable_template_pages, :position, :integer, { :null => true, :default => nil }
  end

  def down
  end
end
