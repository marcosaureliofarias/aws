class AddDescriptionToPrintableTemplates < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_printable_templates, :description, :string, {:limit => 255}
  end
end
