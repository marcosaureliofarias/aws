require 'easy_extensions/spec_helper'

describe 'Easy Calculation', type: :feature, logged: :admin do

  let(:project) { FactoryGirl.create(:project, :enabled_module_names => %w(issue_tracking easy_calculation), number_of_issues: 3) }
  let(:uri) { easy_calculation_path(project) }

  it 'list issues' do
    with_easy_settings(calculation: {tracker_ids: project.tracker_ids}) do
      visit uri
      expect(page).to have_css('tr.issue-solution-row', :count => 3)
    end
  end

  it 'create custom item', js: true do
    visit uri
    page.fill_in 'easy_calculation_item_name', with: 'Custom Item'
    page.fill_in 'easy_calculation_item_hours', with: 10
    page.fill_in 'easy_calculation_item_unit', with: 'KG'
    page.fill_in 'easy_calculation_item_rate', with: 700
    page.fill_in 'easy_calculation_item_calculation_discount', with: 20
    page.find('a.save-calculation').click
    wait_for_ajax
    expect(page).to have_css('tr.item-solution-row td:nth-child(2)', text: 'Custom Item')
    expect(page).to have_css('tr.item-solution-row td:nth-child(4)', text: '10')
    expect(page).to have_css('tr.item-solution-row td:nth-child(5)', text: '700')
    expect(page).to have_css('tr.item-solution-row td:nth-child(6)', text: '20')
    expect(page).to have_css('tr.item-solution-row td:nth-child(7)', text: /6.?980/)
  end

  it 'warning unless fixed activity' do
    with_easy_settings({project_fixed_activity: false}, project) do
      visit uri
      expect(page).to have_css('div.warning')
    end
  end

  it 'no warning if fixed activity' do
    with_easy_settings({project_fixed_activity: true}, project) do
      visit uri
      expect(page).not_to have_css('div.warning')
    end
  end

  it 'set project as planned', js: true do
    visit uri
    expect(page).to have_css('#project-settings-container')

    check 'project_is_planned'
    expect(page).not_to have_css('#project-settings-container')

#    wait_for_ajax(60)
#
#    p = Project.find(project.id)
#    expect(p.is_planned).to be true
  end

end
