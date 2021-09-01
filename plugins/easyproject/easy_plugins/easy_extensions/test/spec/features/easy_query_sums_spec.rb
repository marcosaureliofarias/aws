require 'easy_extensions/spec_helper'

feature 'Easy query sums', :logged => :admin, :js => true, :slow => true do

  let(:project) { FactoryGirl.create(:project, :number_of_issues => 0, :number_of_issue_categories => 0, :number_of_subprojects => 0) }
  let(:issues) { FactoryGirl.create_list(:issue, 30, :estimated_hours => 1, :project => project) }

  scenario 'correct sum' do
    issues
    visit project_issues_path(project, :set_filter => '1', :show_sum_row => '1',
                              :column_names        => ['subject', 'estimated_hours'])
    expect(page.find('.easy-query-heading-count')).to have_content('30')
    expect(page.first('.entities tbody > tr')).to have_content('1')
    expect(page.find('#totalsum-summary')).to have_content('30')
  end

end
