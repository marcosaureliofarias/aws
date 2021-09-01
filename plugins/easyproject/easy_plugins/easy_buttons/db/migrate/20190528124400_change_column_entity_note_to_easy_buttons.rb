class ChangeColumnEntityNoteToEasyButtons < ActiveRecord::Migration[4.2]
  MYSQL_TEXT_LIMIT = 4294967295

  def up
    if column_exists?(:easy_buttons, :entity_note)
      change_column :easy_buttons, :entity_note, :text
    else
      add_column :easy_buttons, :entity_note, :text
    end

    adapter_name = ActiveRecord::Base.connection_config[:adapter]

    case adapter_name.downcase
    when /(mysql|mariadb)/
      change_column :easy_buttons, :entity_note, :text, limit: MYSQL_TEXT_LIMIT
    end
  end

  def down
    remove_column :easy_buttons, :entity_note
  end
end
