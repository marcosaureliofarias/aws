class TestCasesBaseController < ApplicationController
  private

  def authorize_test_cases
    projects_tree = [nil]
    projects_tree = @project.hierarchy.has_module(:test_cases).order(:lft) if @project
    deny_access unless projects_tree.any? {|project| User.current.allowed_to?({controller: controller_name, action: action_name}, project, global: true) }
  end
end