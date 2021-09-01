class CreateReArtifactBaselines < ActiveRecord::Migration[5.2]
  def change
    create_table :re_artifact_baselines do |t|
      t.references :project, index: true
      t.string :name
      t.text :description
      t.timestamps
    end
  end
end
