class ReArtifactBaselinesReArtifactPropertiesVersion < ActiveRecord::Base
  belongs_to :re_artifact_properties_version
  belongs_to :re_artifact_baseline
end
