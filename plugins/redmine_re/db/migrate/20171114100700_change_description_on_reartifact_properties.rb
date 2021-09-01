class ChangeDescriptionOnReartifactProperties < ActiveRecord::Migration[4.2]
  def up
    change_column :re_artifact_properties, :description, :text, limit: 16.megabytes - 1
  end
end
