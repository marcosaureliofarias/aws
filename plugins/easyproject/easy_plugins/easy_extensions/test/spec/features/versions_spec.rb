require 'easy_extensions/spec_helper'

feature 'versions', js: true, logged: true do

  let(:version) { FactoryGirl.create(:version, :sharing => 'system') }
  let(:issue) { FactoryGirl.create(:issue, :estimated_hours => 1, :fixed_version => version) }
  let(:time_entry) { FactoryGirl.create(:time_entry, :hours => 1, :issue => issue) }

  context 'spent & estimated hours permissions' do
    def init(*permissions)
      role = Role.non_member
      role.add_permission!(*permissions)
      role.remove_permission!(*([:view_issues, :view_estimated_hours, :view_time_entries] - permissions))
      role.reload
      issue; time_entry;
      visit version_path(version)
    end

    scenario 'without permissions' do
      init(:view_issues)
      expect(page).to have_css('.roadmap.selected')
      expect(page).not_to have_css('.time-tracking')
      expect(page).not_to have_css('.estimated-hours')
      expect(page).not_to have_css('.spent-hours')
    end

    scenario 'spent-hours' do
      init(:view_issues, :view_time_entries)
      sidebar_closed = page.has_css?('.nosidebar')
      if sidebar_closed
        page.find(".sidebar-control > a").click
      end
      expect(page).to have_css('.roadmap.selected')
      expect(page).to have_css('.time-tracking')
      expect(page).not_to have_css('.estimated-hours')
      expect(page).to have_css('.spent-hours')
    end

    scenario 'estimated-hours' do
      init(:view_issues, :view_estimated_hours)
      sidebar_closed = page.has_css?('.nosidebar')
      if sidebar_closed
        page.find(".sidebar-control > a").click
      end
      expect(page).to have_css('.roadmap.selected')
      expect(page).to have_css('.time-tracking')
      expect(page).to have_css('.estimated-hours')
      expect(page).not_to have_css('.spent-hours')
    end

    scenario 'spent & estimated-hours' do
      init(:view_issues, :view_estimated_hours, :view_time_entries)
      sidebar_closed = page.has_css?('.nosidebar')
      if sidebar_closed
        page.find(".sidebar-control > a").click
      end
      expect(page).to have_css('.roadmap.selected')
      expect(page).to have_css('.time-tracking')
      expect(page).to have_css('.estimated-hours')
      expect(page).to have_css('.spent-hours')
    end
  end

  context 'project roadmap', :logged => :admin do
    let(:project) { FactoryGirl.create(:project) }
    let(:project_version) { FactoryGirl.create(:version, :project => project) }

    scenario 'project roadmap loads' do
      visit(project_roadmap_path(version.project))
      expect(page).to have_css('.roadmap.selected')
    end

    scenario 'project roadmap create new milestone' do
      visit(new_project_version_path(project))
      version_name = 'New Version'
      page.fill_in 'version_name', with: version_name
      page.find("input[type='submit']").click
      expect(page.find('.entities').text).to include(version_name)
      visit(project_roadmap_path(project))
      expect(page).to have_css('.roadmap.selected')
    end

    scenario 'show query groups' do
      project_version
      visit settings_project_path(project, :tab => 'versions', :set_filter => '1', :group_by => ['status'], :load_groups_opened => '1')
      wait_for_ajax
      expect(page).to have_css('tr.group.open')
      expect(page).to have_css(".version_#{project_version.id}")
    end
  end

end
