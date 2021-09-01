class ExpectedResultToCustomField < EasyExtensions::EasyDataMigration
  def up
    cf = TestCaseCustomField.find_by(internal_name: 'test_case_expected_result')
    unless cf.present?
      cf = TestCaseCustomField.create name: 'Expected result',
                                      internal_name: 'test_case_expected_result',
                                      field_format: 'text',
                                      searchable: true,
                                      editable: true,
                                      visible: true,
                                      is_filter: true,
                                      format_store: { text_formatting: 'full' },
                                      is_primary: true,
                                      show_empty: false,
                                      non_deletable: true
    end

    TestCase.where.not(expected_result: nil).find_each do |tc|
      cv = tc.custom_values.find_by(custom_field_id: cf.id)
      unless cv.present?
        tc.custom_values.create(custom_field_id: cf.id, value: tc.expected_result)
      end
    end
  end
end
