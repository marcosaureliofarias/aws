class AddEasySystemFlagToEasyPdfThemes < ActiveRecord::Migration[4.2]

  def up
    add_column :easy_pdf_themes, :easy_system_flag, :boolean, :default => false, :null => false
  end

  def down
    remove_column :easy_pdf_themes, :easy_system_flag
  end

end
