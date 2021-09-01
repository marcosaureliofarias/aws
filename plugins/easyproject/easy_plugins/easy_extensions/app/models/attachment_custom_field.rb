class AttachmentCustomField < CustomField
  def type_name
    :label_file_plural
  end

  def form_fields
    super + [:is_filter]
  end
end
