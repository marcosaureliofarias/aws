module ReArtifactPropertiesTypes
  def self.re_artifact_types_all 
    return re_artifact_types << "Project"
  end
  
  def self.re_artifact_types 
    return %w(ReSection ReRequirement ReChangeRequest)
  end


end
