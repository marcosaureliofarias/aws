# encoding: utf-8
class FixDiacritics < ActiveRecord::Migration[4.2]

  def self.up
    #EasyKnowledgeStory
    EasyKnowledgeStory.where("description LIKE ? ", '%&scaron;%').update_all("description = REPLACE(description,'&scaron;','š')")
    EasyKnowledgeStory.where("description LIKE ? ", '%&Scaron;%').update_all("description = REPLACE(description,'&Scaron;','Š')")

    EasyKnowledgeStory.where("description LIKE ? ", '%&yacute;%').update_all("description = REPLACE(description,'&yacute;','ý')")
    EasyKnowledgeStory.where("description LIKE ? ", '%&Yacute;%').update_all("description = REPLACE(description,'&Yacute;','Ý')")

    EasyKnowledgeStory.where("description LIKE ? ", '%&aacute;%').update_all("description = REPLACE(description,'&aacute;','á')")
    EasyKnowledgeStory.where("description LIKE ? ", '%&Aacute;%').update_all("description = REPLACE(description,'&Aacute;','Á')")

    EasyKnowledgeStory.where("description LIKE ? ", '%&iacute;%').update_all("description = REPLACE(description,'&iacute;','í')")
    EasyKnowledgeStory.where("description LIKE ? ", '%&Iacute;%').update_all("description = REPLACE(description,'&Iacute;','Í')")

    EasyKnowledgeStory.where("description LIKE ? ", '%&eacute;%').update_all("description = REPLACE(description,'&eacute;','é')")
    EasyKnowledgeStory.where("description LIKE ? ", '%&Eacute;%').update_all("description = REPLACE(description,'&Eacute;','É')")

    EasyKnowledgeStory.where("description LIKE ? ", '%&uacute;%').update_all("description = REPLACE(description,'&uacute;','ú')")
    EasyKnowledgeStory.where("description LIKE ? ", '%&Uacute;%').update_all("description = REPLACE(description,'&Uacute;','Ú')")
  end

  def self.down
  end

end
