class ReArtifactPropertiesCustomField < CustomField
  def type_name
    :label_re_artifact_properties_plural
  end

  def form_fields
    [:is_filter]
  end
end