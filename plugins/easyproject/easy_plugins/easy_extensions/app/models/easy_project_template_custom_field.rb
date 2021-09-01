class EasyProjectTemplateCustomField < CustomField

  def self.customized_class
    Project
  end

  def is_required?
    false
  end

  def type_name
    :label_templates_plural
  end

end
