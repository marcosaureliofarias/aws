class ChangeTextInWikiContentsToLongText < ActiveRecord::Migration[4.2]
  def up
#    adapter_name = WikiContent.connection_config[:adapter]
#    case adapter_name.downcase
#    when 'mysql', 'mysql2'
#      change_column :wiki_contents, :text, :text, {:limit => 4294967295}
#    end
  end

  def down
  end
end
