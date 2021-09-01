class AddEasyPageTemplateIdToEasyUserTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_user_types, :easy_page_template_id, :integer, default: nil
  end
end
