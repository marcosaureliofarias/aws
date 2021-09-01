class FilledOldHelpdeskMailTemplatesName < EasyExtensions::EasyDataMigration
  def up
    mail_templates = EasyHelpdeskMailTemplate.preload(:mailboxes).all
    mail_templates.each do |template|
      template.update_column(:name, template.caption)
    end
  end
  def down

  end
end
