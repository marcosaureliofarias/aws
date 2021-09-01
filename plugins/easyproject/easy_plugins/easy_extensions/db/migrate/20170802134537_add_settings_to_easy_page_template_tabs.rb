class AddSettingsToEasyPageTemplateTabs < ActiveRecord::Migration[4.2]

  def up
    adapter_name = ActiveRecord::Base.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      add_column :easy_page_template_tabs, :settings, :text, limit: 4_294_967_295
    else
      add_column :easy_page_template_tabs, :settings, :text
    end
  end

  def down
    remove_column :easy_page_template_tabs, :settings
  end

end
