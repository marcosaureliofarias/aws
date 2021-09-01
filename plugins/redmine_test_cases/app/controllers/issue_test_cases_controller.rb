class IssueTestCasesController < ApplicationController
  before_action :find_issue
  before_action :authorize

  def list
    respond_to do |format|
      format.js
      format.html
    end
  end

  def add
    @test_cases = TestCase.visible.where(id: params[:test_case_ids]).uniq
    @issue.test_cases += @test_cases
    @test_cases.each do |test_case|
      test_case.test_case_issue_executions.create(issue: @issue, author: User.current)
    end
    respond_to do |format|
      format.html {redirect_back_or_default issue_path(@issue)}
    end
  end

  private

  def find_issue
    @issue = Issue.find params[:id]
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end