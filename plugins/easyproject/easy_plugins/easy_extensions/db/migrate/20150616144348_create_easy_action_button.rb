class CreateEasyActionButton < ActiveRecord::Migration[4.2]

  MYSQL_TEXT_LIMIT = 4294967295

  def up
    create_table :easy_action_buttons do |t|
      t.string :name, null: false
      t.string :entity_type, null: false
      t.integer :project_id
      t.boolean :active, null: false, default: true
      t.string :background, limit: 7, default: '#52afe5'
      t.string :font_color, limit: 7, default: '#ffffff'
      t.text :conditions
      t.text :actions
      t.text :conditions_cache
      t.text :actions_cache

      t.timestamps
    end

    adapter_name = ActiveRecord::Base.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      change_column :easy_action_buttons, :conditions, :text, limit: MYSQL_TEXT_LIMIT
      change_column :easy_action_buttons, :actions, :text, limit: MYSQL_TEXT_LIMIT
      change_column :easy_action_buttons, :conditions_cache, :text, limit: MYSQL_TEXT_LIMIT
      change_column :easy_action_buttons, :actions_cache, :text, limit: MYSQL_TEXT_LIMIT
    end
  end

  def down
    drop_table :easy_action_buttons
  end
end
