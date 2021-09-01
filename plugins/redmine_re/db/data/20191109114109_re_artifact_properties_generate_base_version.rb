class ReArtifactPropertiesGenerateBaseVersion < EasyExtensions::EasyDataMigration
  def up
    ReArtifactProperties.all.each do |re_artifact_properties|
      re_artifact_properties.create_version
    end
  end
end
