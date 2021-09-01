class ChangeEasyPrintableTemplatePages < ActiveRecord::Migration[4.2]
  def up
    adapter_name = EasyPrintableTemplatePage.connection_config[:adapter]
    case adapter_name.downcase
    when /(mysql|mariadb)/
      remove_column :easy_printable_template_pages, :page_text
      add_column :easy_printable_template_pages, :page_text, :text, {:null => false, :limit => 4294967295}
    end
  end

  def down
  end
end
