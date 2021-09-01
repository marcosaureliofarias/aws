require File.expand_path('../easy_gantt_resources/test/test_helper.rb')


class IssueTest < ActiveSupport::TestCase
  fixtures :issues

  def test_build_resources_params_returns_empty_array_when_zero_hours_to_allocate
    issue = issues(:issue_with_zero_hours_to_allocate)
    resources = issue.send(:build_resources_params)

    assert_equal resources, []
  end

  def test_build_resources_params_builds_zero_hours_resources_for_weekend_days
    issue = issues(:issue_over_weekend)
    resources = issue.send(:build_resources_params)
    weekend_resources = resources.select {|resource| resource["date"].wday >= 6 }
    zero_hours_weekend_resources = weekend_resources.select {|resource| resource["hours"] == 0 }

    assert_equal weekend_resources, zero_hours_weekend_resources
  end

  def test_build_resources_params_builds_seven_full_day_resources_for_full_week_issue_when_assigned_to_user_without_other_resources
    issue = issues(:issue_over_weekend)
    resources = issue.send(:build_resources_params)
    full_day_resources = resources.select {|resource| resource["hours"] == EasyGanttResource.hours_per_day }

    assert full_day_resources.size == 7
  end

  def test_build_resources_params_builds_one_hour_resources_for_five_days_issue_estimated_to_five_hours
    issue = issues(:issue_for_five_days_estimated_to_five_hours)
    resources = issue.send(:build_resources_params)
    one_hour_resources = resources.select {|resource| resource["hours"] == 1 }

    assert one_hour_resources.size == 5
  end

  def test_build_resources_params_should_not_build_resources_over_max_working_day_hours
    issue = issues(:issue_with_estimation_higher_than_max_daily_hours)
    resources = issue.send(:build_resources_params)
    resources_over_max_daily_hours = resources.select {|resource| resource["hours"] > EasyGanttResource.hours_per_day }

    assert resources_over_max_daily_hours.blank?
  end

  def test_build_resources_params_builds_resources_over_due_date_when_issue_estimation_is_higher_than_available_resources
    issue = issues(:issue_with_estimation_higher_than_max_daily_hours)
    resources = issue.send(:build_resources_params)
    resources_over_issue_due_date = resources.select {|resource| resource["date"] > issue.due_date }

    assert resources_over_issue_due_date.present?
  end

  def test_build_resources_params_should_not_build_non_custom_resource_when_custom_resource_exists
    issue = issues(:issue_over_weekend)
    working_day_resource = { "issue_id" => issue.id, "user_id" => issue.assigned_to_id, "custom" => true, "date" => '2020-12-04', "hours" => 5.0 }
    weekend_resource = { "issue_id" => issue.id, "user_id" => issue.assigned_to_id, "custom" => true, "date" => '2020-12-05', "hours" => 5.0 }
    EasyGanttResource.save_issues_resources(issue => [working_day_resource, weekend_resource])

    resources = issue.send(:build_resources_params)
    unwanted_resources = resources.select do |resource|
      resource["custom"] == false &&
      (resource["date"] == weekend_resource["date"].to_date || resource["date"] == working_day_resource["date"].to_date)
    end

    assert unwanted_resources.blank?
  end

end
