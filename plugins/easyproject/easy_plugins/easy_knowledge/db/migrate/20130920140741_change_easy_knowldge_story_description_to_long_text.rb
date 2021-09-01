class ChangeEasyKnowldgeStoryDescriptionToLongText < ActiveRecord::Migration[4.2]
  def up
    adapter_name = EasyKnowledgeStory.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      change_column :easy_knowledge_stories, :description, :text, {:limit => 4294967295, :default => nil}
    end
  end

  def down
  end
end
