class AddCustomFieldsToTestPlan < EasyExtensions::EasyDataMigration
  def up
    cf_begin = TestPlanCustomField.find_by(internal_name: 'test_plan_begin_date')
    unless cf_begin.present?
      cf_begin = TestPlanCustomField.create name: 'Test plan begin date',
                                            internal_name: 'test_plan_begin_date',
                                            field_format: 'date',
                                            searchable: true,
                                            editable: true,
                                            visible: true,
                                            is_filter: true,
                                            format_store: { text_formatting: 'full' },
                                            is_primary: true,
                                            show_empty: false,
                                            non_deletable: true
    end

    cf_end = TestPlanCustomField.find_by(internal_name: 'test_plan_end_date')
    unless cf_end.present?
      cf_end = TestPlanCustomField.create name: 'Test plan end date',
                                          internal_name: 'test_plan_end_date',
                                          field_format: 'date',
                                          searchable: true,
                                          editable: true,
                                          visible: true,
                                          is_filter: true,
                                          format_store: { text_formatting: 'full' },
                                          is_primary: true,
                                          show_empty: false,
                                          non_deletable: true
    end
  end
end
