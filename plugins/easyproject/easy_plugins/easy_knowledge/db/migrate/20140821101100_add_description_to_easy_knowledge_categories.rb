class AddDescriptionToEasyKnowledgeCategories < ActiveRecord::Migration[4.2]
  def up
    adapter_name = EasyKnowledgeStory.connection_config[:adapter]
    change_table :easy_knowledge_categories do |t|
      case adapter_name.downcase
      when /(mysql|mariadb)/
        t.text :description, {:limit => 4294967295}
      else
        t.text :description
      end
    end
  end

  def down
    remove_column :easy_knowledge_categories, :description
  end
end
