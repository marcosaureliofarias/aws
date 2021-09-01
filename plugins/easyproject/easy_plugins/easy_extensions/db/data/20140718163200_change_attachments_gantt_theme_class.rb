class ChangeAttachmentsGanttThemeClass < EasyExtensions::EasyDataMigration

  def self.up
    Attachment.where(container_type: 'EasyGanttTheme').update_all(container_type: 'EasyPdfTheme')
  end

  def self.down
    Attachment.where(container_type: 'EasyPdfTheme').update_all(container_type: 'EasyGanttTheme')
  end

end
