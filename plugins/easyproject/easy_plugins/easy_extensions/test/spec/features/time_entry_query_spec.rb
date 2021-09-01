require 'easy_extensions/spec_helper'

feature 'Time entry query view', :js => true, :logged => :admin do
  context 'total hours' do
    scenario 'default' do
      visit easy_time_entries_path
      sidebar_closed = page.has_css?('.nosidebar')
      if sidebar_closed
        page.find(".sidebar-control > a").click
      end
      expect(page).to have_css('.total-hours')
    end

    scenario 'without hours column' do
      visit easy_time_entries_path(:set_filter => '1', :easy_query => { :column_names => ['project'] })
      sidebar_closed = page.has_css?('.nosidebar')
      if sidebar_closed
        page.find(".sidebar-control > a").click
      end
      expect(page).to have_css('.total-hours')
    end
  end

  context 'sorts' do
    let!(:datetime_cf) { FactoryGirl.create(:time_entry_custom_field, :field_format => 'datetime', :min_length => nil, :max_length => nil) }
    let!(:date_cf) { FactoryGirl.create(:time_entry_custom_field, :field_format => 'date', :min_length => nil, :max_length => nil) }
    ['2016-01-02', '2016-01-03', '2016-01-04', '2016-01-03', '2016-02-04'].each_with_index do |date, i|
      let!(:"time_entry_#{i + 1}") do
        FactoryGirl.create(:time_entry, :spent_on => date.to_date, custom_field_values: { datetime_cf.id.to_s => date, date_cf.id.to_s => date })
      end
    end

    scenario 'date columns' do
      visit easy_time_entries_path(:set_filter => '1', :column_names => ['spent_on'], :group_by => ['spent_on'], :load_groups_opened => '1', :sort => 'spent_on')
      wait_for_ajax
      page.find('.entities') # wait
      expect(page.all('td.spent_on').map(&:text)).to eq ['01/02/2016', '01/03/2016', '01/03/2016', '01/04/2016', '02/04/2016']
      expect(page).to have_css('.list .group', :count => 2)

      cf = "cf_#{date_cf.id}"
      visit easy_time_entries_path(:set_filter => '1', :column_names => [cf], :group_by => [cf], :load_groups_opened => '1', :sort => cf)
      wait_for_ajax
      page.find('.entities') # wait
      expect(page.all("td.#{cf}").map(&:text)).to eq ['01/02/2016', '01/03/2016', '01/03/2016', '01/04/2016', '02/04/2016']
      expect(page).to have_css('.list .group', :count => 2)

      cf = "cf_#{datetime_cf.id}"
      visit easy_time_entries_path(:set_filter => '1', :column_names => [cf], :group_by => [cf], :load_groups_opened => '1', :sort => cf)
      wait_for_ajax
      page.find('.entities') # wait
      expect(page.all("td.#{cf}").map(&:text)).to eq ['01/02/2016 12:00 AM', '01/03/2016 12:00 AM', '01/03/2016 12:00 AM', '01/04/2016 12:00 AM', '02/04/2016 12:00 AM']
      expect(page).to have_css('.list .group', :count => 2)
    end
  end

  context 'groups' do
    let!(:project) { FactoryBot.create(:project, enabled_module_names: ['issue_tracking', 'time_tracking'], number_of_issues: 0, members: [User.current]) }
    let!(:cf_user1) { FactoryBot.create(:issue_custom_field, field_format: 'user', is_for_all: true, is_filter: true, trackers: project.trackers) }
    let!(:cf_user2) { FactoryBot.create(:issue_custom_field, field_format: 'user', is_for_all: true, is_filter: true, trackers: project.trackers) }
    let!(:issue) do
      _issue = FactoryBot.create(:issue, project: project, due_date: Date.today)
      _issue.reload
      _issue.custom_field_values = {
          cf_user1.id.to_s => User.current.id.to_s,
          cf_user2.id.to_s => User.current.id.to_s
      }
      _issue.save!
      _issue
    end
    let!(:time_entry) { FactoryBot.create(:time_entry, issue: issue) }

    scenario 'multigroup' do
      cf1_name = "cf_#{cf_user1.id}"
      cf2_name = "cf_#{cf_user2.id}"
      visit easy_time_entries_path(set_filter: '1', column_names: ['spent_on'], group_by: [cf1_name, cf2_name], load_groups_opened: '0')
      wait_for_ajax
      expect(page).to have_css(".multigrouping a.user", count: 2)
    end
  end

  context 'report' do
    let(:q) { FactoryGirl.create(:easy_time_entry_query,
                                 :group_by      => 'project',
                                 :sort_criteria => [['spent_on', 'asc'], ['user', 'asc']],
                                 :filters       => { 'spent_on' => { :operator => 'date_period_1',
                                                                     :values   => { :period => 'all' } } }) }
    let(:time_entry) { FactoryGirl.create(:time_entry) }

    scenario 'with saved query' do
      time_entry
      visit report_easy_time_entries_path(:set_filter => '1', :query_id => q.id.to_s)
      page.find("#criterias [value='project']").select_option
      report = page.find('#time-report')
      expect(report).to have_content(I18n.t(:label_project))
      expect(report).to have_content(time_entry.project.name)
      page.find("#criterias [value='user']").select_option
      report = page.find('#time-report')
      expect(report).to have_content(Regexp.new(I18n.t(:label_user), 'i'))
      expect(report).to have_content(time_entry.user.name)
    end
  end
end
