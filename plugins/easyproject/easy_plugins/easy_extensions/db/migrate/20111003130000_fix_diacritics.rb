# encoding: utf-8
class FixDiacritics < ActiveRecord::Migration[4.2]

  def self.up
    #Issue
    Issue.where("description like '%&scaron;%'").update_all("description = REPLACE(description,'&scaron;','š')")
    Issue.where("description like '%&Scaron;%'").update_all("description = REPLACE(description,'&Scaron;','Š')")

    Issue.where("description like '%&yacute;%'").update_all("description = REPLACE(description,'&yacute;','ý')")
    Issue.where("description like '%&Yacute;%'").update_all("description = REPLACE(description,'&Yacute;','Ý')")

    Issue.where("description like '%&aacute;%'").update_all("description = REPLACE(description,'&aacute;','á')")
    Issue.where("description like '%&Aacute;%'").update_all("description = REPLACE(description,'&Aacute;','Á')")

    Issue.where("description like '%&iacute;%'").update_all("description = REPLACE(description,'&iacute;','í')")
    Issue.where("description like '%&Iacute;%'").update_all("description = REPLACE(description,'&Iacute;','Í')")

    Issue.where("description like '%&eacute;%'").update_all("description = REPLACE(description,'&eacute;','é')")
    Issue.where("description like '%&Eacute;%'").update_all("description = REPLACE(description,'&Eacute;','É')")

    Issue.where("description like '%&uacute;%'").update_all("description = REPLACE(description,'&uacute;','ú')")
    Issue.where("description like '%&Uacute;%'").update_all("description = REPLACE(description,'&Uacute;','Ú')")

    #Journal
    Journal.where("notes like '%&scaron;%'").update_all("notes = REPLACE(notes,'&scaron;','š')")
    Journal.where("notes like '%&Scaron;%'").update_all("notes = REPLACE(notes,'&Scaron;','Š')")

    Journal.where("notes like '%&yacute;%'").update_all("notes = REPLACE(notes,'&yacute;','ý')")
    Journal.where("notes like '%&Yacute;%'").update_all("notes = REPLACE(notes,'&Yacute;','Ý')")

    Journal.where("notes like '%&aacute;%'").update_all("notes = REPLACE(notes,'&aacute;','á')")
    Journal.where("notes like '%&Aacute;%'").update_all("notes = REPLACE(notes,'&Aacute;','Á')")

    Journal.where("notes like '%&iacute;%'").update_all("notes = REPLACE(notes,'&iacute;','í')")
    Journal.where("notes like '%&Iacute;%'").update_all("notes = REPLACE(notes,'&Iacute;','Í')")

    Journal.where("notes like '%&eacute;%'").update_all("notes = REPLACE(notes,'&eacute;','é')")
    Journal.where("notes like '%&Eacute;%'").update_all("notes = REPLACE(notes,'&Eacute;','É')")

    Journal.where("notes like '%&uacute;%'").update_all("notes = REPLACE(notes,'&uacute;','ú')")
    Journal.where("notes like '%&Uacute;%'").update_all("notes = REPLACE(notes,'&Uacute;','Ú')")

    #News
    News.where("description like '%&scaron;%'").update_all("description = REPLACE(description,'&scaron;','š')")
    News.where("description like '%&Scaron;%'").update_all("description = REPLACE(description,'&Scaron;','Š')")

    News.where("description like '%&yacute;%'").update_all("description = REPLACE(description,'&yacute;','ý')")
    News.where("description like '%&Yacute;%'").update_all("description = REPLACE(description,'&Yacute;','Ý')")

    News.where("description like '%&aacute;%'").update_all("description = REPLACE(description,'&aacute;','á')")
    News.where("description like '%&Aacute;%'").update_all("description = REPLACE(description,'&Aacute;','Á')")

    News.where("description like '%&iacute;%'").update_all("description = REPLACE(description,'&iacute;','í')")
    News.where("description like '%&Iacute;%'").update_all("description = REPLACE(description,'&Iacute;','Í')")

    News.where("description like '%&eacute;%'").update_all("description = REPLACE(description,'&eacute;','é')")
    News.where("description like '%&Eacute;%'").update_all("description = REPLACE(description,'&Eacute;','É')")

    News.where("description like '%&uacute;%'").update_all("description = REPLACE(description,'&uacute;','ú')")
    News.where("description like '%&Uacute;%'").update_all("description = REPLACE(description,'&Uacute;','Ú')")

    #Document
    Document.where("description like '%&scaron;%'").update_all("description = REPLACE(description,'&scaron;','š')")
    Document.where("description like '%&Scaron;%'").update_all("description = REPLACE(description,'&Scaron;','Š')")

    Document.where("description like '%&yacute;%'").update_all("description = REPLACE(description,'&yacute;','ý')")
    Document.where("description like '%&Yacute;%'").update_all("description = REPLACE(description,'&Yacute;','Ý')")

    Document.where("description like '%&aacute;%'").update_all("description = REPLACE(description,'&aacute;','á')")
    Document.where("description like '%&Aacute;%'").update_all("description = REPLACE(description,'&Aacute;','Á')")

    Document.where("description like '%&iacute;%'").update_all("description = REPLACE(description,'&iacute;','í')")
    Document.where("description like '%&Iacute;%'").update_all("description = REPLACE(description,'&Iacute;','Í')")

    Document.where("description like '%&eacute;%'").update_all("description = REPLACE(description,'&eacute;','é')")
    Document.where("description like '%&Eacute;%'").update_all("description = REPLACE(description,'&Eacute;','É')")

    Document.where("description like '%&uacute;%'").update_all("description = REPLACE(description,'&uacute;','ú')")
    Document.where("description like '%&Uacute;%'").update_all("description = REPLACE(description,'&Uacute;','Ú')")

    #Project
    Project.where("description like '%&scaron;%'").update_all("description = REPLACE(description,'&scaron;','š')")
    Project.where("description like '%&Scaron;%'").update_all("description = REPLACE(description,'&Scaron;','Š')")

    Project.where("description like '%&yacute;%'").update_all("description = REPLACE(description,'&yacute;','ý')")
    Project.where("description like '%&Yacute;%'").update_all("description = REPLACE(description,'&Yacute;','Ý')")

    Project.where("description like '%&aacute;%'").update_all("description = REPLACE(description,'&aacute;','á')")
    Project.where("description like '%&Aacute;%'").update_all("description = REPLACE(description,'&Aacute;','Á')")

    Project.where("description like '%&iacute;%'").update_all("description = REPLACE(description,'&iacute;','í')")
    Project.where("description like '%&Iacute;%'").update_all("description = REPLACE(description,'&Iacute;','Í')")

    Project.where("description like '%&eacute;%'").update_all("description = REPLACE(description,'&eacute;','é')")
    Project.where("description like '%&Eacute;%'").update_all("description = REPLACE(description,'&Eacute;','É')")

    Project.where("description like '%&uacute;%'").update_all("description = REPLACE(description,'&uacute;','ú')")
    Project.where("description like '%&Uacute;%'").update_all("description = REPLACE(description,'&Uacute;','Ú')")
  end

  def self.down
  end

end
