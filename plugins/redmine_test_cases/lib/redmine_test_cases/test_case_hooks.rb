module RedmineTestCases
  class TestCaseHooks < Redmine::Hook::ViewListener

    render_on :view_custom_fields_form_test_case_custom_field, partial: 'custom_fields/view_custom_fields_form_test_case_custom_field'

  end
end
