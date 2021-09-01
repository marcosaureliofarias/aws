class AddAcceptanceCriteriaToReArtifactProperties < ActiveRecord::Migration[4.2]
  def change
    if !column_exists?(:re_artifact_properties, :acceptance_criteria)
      add_column :re_artifact_properties, :acceptance_criteria, :text
    end
  end
end
