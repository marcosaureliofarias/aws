class AddXmlPngToDiagramVersions < ActiveRecord::Migration[5.2]
  def change
    add_column :diagram_versions, :xml_png, :text, limit: 16.megabytes - 1
  end
end
