class AddXmlPngToDiagrams < ActiveRecord::Migration[5.2]
  def change
    add_column :diagrams, :xml_png, :text, limit: 16.megabytes - 1
  end
end
