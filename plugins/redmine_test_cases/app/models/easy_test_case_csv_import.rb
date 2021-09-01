class EasyTestCaseCsvImport < EasyEntityCsvImport
  def get_available_entity_types
    %w(TestCase)
  end

  def entity_type
    'TestCase'
  end

  def param_key
    self.class.name.underscore.tr('/','_')
  end

  def assignable_entity_columns
    return @assignable_entity_columns if @assignable_entity_columns.present?
    @assignable_entity_columns = AvailableColumns.new
    @assignable_entity_columns << EasyEntityImportAttribute.new(:name, required: true)
    %W(easy_external_id id scenario project_id author_id).each do |c|
      @assignable_entity_columns << EasyEntityImportAttribute.new(c)
    end
    TestCaseCustomField.visible.each do |c|
      @assignable_entity_columns << EasyEntityImportAttribute.new("cf_#{c.id}", title: c.name)
    end
    @assignable_entity_columns
  end

  def import_test_cases?(user = User.current)
    user.allowed_to?(:import_test_cases, nil, global: true)
  end

  def visible?(user = User.current)
    import_test_cases?(user)
  end

  def editable?(user = User.current)
    import_test_cases?(user)
  end

  def deletable?(user = User.current)
    import_test_cases?(user)
  end

  def attachments_visible?(user = User.current)
    visible?(user)
  end

  def attachments_editable?(user = User.current)
    editable?(user)
  end

  def attachments_deletable?(user = User.current)
    deletable?(user)
  end
end
