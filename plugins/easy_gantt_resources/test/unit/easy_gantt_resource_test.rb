require File.expand_path("../easy_gantt_resources/test/test_helper.rb")

class EasyGanttResourceTest < ActiveSupport::TestCase
  fixtures :issues

  def test_save_issue_resources_does_not_rewrite_weekend_custom_resource_by_null_hours_non_custom_resource
    issue = issues(:issue_over_weekend)
    custom_resource = { "issue_id" => issue.id, "user_id" => 1, "custom" => true, "date" => '2015-11-21', "hours" => 5.0 }
    non_custom_resource = { "issue_id" => issue.id, "user_id" => 1, "custom" => false, "date" => '2015-11-21', "hours" => 0.0 }

    saved, unsaved = EasyGanttResource.save_issues_resources(issue => [custom_resource, non_custom_resource])

    assert EasyGanttResource.where(custom_resource).first
  end

end
