class RenameEasyGanttThemesToEasyPdfThemes < ActiveRecord::Migration[4.2]

  def change
    rename_table :easy_gantt_themes, :easy_pdf_themes
  end

end