module TestCaseIssueExecutionsHelper

  def render_api_test_case_issue_execution(api, test_case_issue_execution)
    api.test_case_issue_execution do
      api.id test_case_issue_execution.id
      api.test_case test_case_issue_execution.test_case
      api.result_id test_case_issue_execution.result_id
      api.author_id test_case_issue_execution.author_id
      api.created_at test_case_issue_execution.created_at
      api.updated_at test_case_issue_execution.updated_at
      render_api_custom_values test_case_issue_execution.visible_custom_field_values, api
      api.array :attachments do
        test_case_issue_execution.attachments.each do |attachment|
          render_api_attachment(attachment, api)
        end
      end if include_in_api_response?('attachments')

      call_hook(:helper_render_api_test_case_issue_execution, {api: api, test_case_issue_execution: test_case_issue_execution})
    end
  end

end
