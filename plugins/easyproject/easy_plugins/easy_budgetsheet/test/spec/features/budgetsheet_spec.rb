require 'easy_extensions/spec_helper'
feature 'Budgetsheet', :js => true do

  context 'get budgetsheet', :logged => true do

    scenario 'user without permission for all statement' do
      Role.non_member.add_permission!(:view_budgetsheet)
      visit '/budgetsheet'
      expect( page ).not_to have_selector('#user-query-automatic-filter')
      page.find('a#top-menu-rich-more-toggler').click
      expect( page).not_to have_selector('#easy_top_menu_more .easy-budgetsheet-find-by-worker', :visible => false)
    end
  end

  context 'is billable', :logged => :admin do
    let(:project) { FactoryGirl.create(:project) }
    let(:time_entry) { FactoryGirl.create(:time_entry) }

    scenario 'default state' do
      with_easy_settings(:show_billable_things => true) do
        with_easy_settings(:billable_things_default_state => true) do
          visit new_easy_time_entry_path(:project_id => project.id)
          expect(page.find('#time_entry_easy_is_billable')).to be_checked
        end
        with_easy_settings(:billable_things_default_state => false) do
          visit new_easy_time_entry_path(:project_id => project.id)
          expect(page.find('#time_entry_easy_is_billable')).not_to be_checked
        end
      end
      with_easy_settings(:show_billable_things => false) do
        visit new_easy_time_entry_path(:project_id => project.id)
        expect(page).not_to have_selector('#time_entry_easy_is_billable')
      end
    end

    scenario 'groups' do
      with_easy_settings(:show_billable_things => true) do
        time_entry
        visit budgetsheet_path(:project_id => project.id, :set_filter => '1', :group_by => 'easy_is_billable', :load_groups_opened => '1', :column_names => ['issue', 'hours', 'estimated_hours'])
        wait_for_ajax
        expect(page).to have_content(time_entry.issue.subject)
        expect(page.find('td.group-name')).to have_content(I18n.t(:general_text_Yes))
        expect(page.find('.group td.hours')).to have_content('1')
        expect(page.find('.group td.estimated_hours')).to have_content('0')
        expect(page.find("#entity-#{time_entry.id} td.hours")).to have_content('1')
        expect(page.find("#entity-#{time_entry.id} td.estimated_hours")).to have_content('0')
      end
    end
  end

  context 'budgetsheet query' do
    let(:query) { FactoryGirl.create(:easy_budget_sheet_query) }
    let(:projects) { FactoryGirl.create_list(:project, 3) }
    let(:issues) do
      result = projects.map do |project|
        FactoryGirl.create_list(:issue, 4, :project => project, :estimated_hours => 4)
      end
      result.flatten
    end
    let(:settings) do
      {
        'easy_budget_sheet_query_list_default_columns' => ['project', 'issue', 'spent_on', 'user', 'hours', 'estimated_hours'],
        'easy_budget_sheet_query_default_filters' => {}
      }
    end

    subject do
      time_entries = []
      issues.each_with_index do |issue, index|
        next if index % 2 == 0
        time_entries << FactoryGirl.create(:time_entry, :issue => issue )
      end
      time_entries.concat(FactoryGirl.create_list(:time_entry, 3, :issue => issues.first ))
    end

    scenario 'User check the sums last month', :slow => true, :logged => :admin do
      hours = subject.sum{|te| te.hours }
      estimated_hours = issues.sum{|i| i.time_entries.any? ? i.estimated_hours : 0 }

      # with_easy_settings(settings) do
      visit "/budgetsheet?query_id=#{query.id}"
      expect( find('#totalsum-summary td.hours').text ).to have_content(hours.to_s)
      expect( find('#totalsum-summary td.estimated_hours').text ).to have_content(estimated_hours.to_s)
      # end
    end
  end

end
