require 'easy_extensions/spec_helper'

feature 'apply filters on issues', js: true, logged: :admin, js_wait: :long do

  def get_filter_by_type(type)
    EasyIssueQuery.new.available_filters.detect { |_, options| options[:type] == type }
  end

  def open_filters
    page.find('#easy-query-toggle-button-filters').click
    wait_for_ajax
  end

  def apply_filters
    wait_for_ajax
    page.find('#filter_buttons .apply-link').click
    wait_for_ajax
  end

  def select_filter(filter_name)
    wait_for_ajax
    page.find("#add_filter_select option[value='#{filter_name}']").select_option
    wait_for_ajax
  end

  context 'apply filters' do
    before(:each) do
      visit issues_path
      wait_for_ajax
      open_filters
    end

    it 'can apply string filter' do
      filter          = get_filter_by_type(:string)
      filter_name     = filter.first
      values_selector = "#values_#{filter_name}"
      select_filter(filter_name)
      page.find(values_selector).set('test')
      apply_filters
      open_filters
      expect(page).to have_selector(values_selector)
      expect(page.find(values_selector).value).to eq('test')
    end

    it 'can apply boolean filter' do
      filter      = get_filter_by_type(:boolean)
      filter_name = filter.first
      select_filter(filter_name)

      values_selector = "#values_#{filter_name}_true"
      page.find(values_selector).set(true)
      apply_filters
      open_filters
      expect(page).to have_selector(values_selector)

      expect(page.find(values_selector)).to be_checked

      values_selector = "#values_#{filter_name}_false"
      page.find(values_selector).set(true)
      apply_filters
      open_filters
      expect(page).to have_selector(values_selector)

      expect(page.find(values_selector)).to be_checked
    end

    it 'can apply date_period by period filter' do
      filter                 = get_filter_by_type(:date_period)
      filter_name            = filter.first
      period1_selector       = "##{filter_name}_date_period_1"
      values_period_selector = "#values_#{filter_name}_period"
      values_period_option   = "#{values_period_selector} option[value='yesterday']"
      select_filter(filter_name)
      page.find(period1_selector).set(true)

      page.find(values_period_option).select_option
      apply_filters
      open_filters
      expect(page).to have_selector(period1_selector)

      expect(page.find(period1_selector)).to be_checked

      expect(page).to have_selector(values_period_option)
    end

    it 'can apply date_period by range filter' do
      filter      = get_filter_by_type(:date_period)
      filter_name = filter.first
      select_filter(filter_name)

      from                 = '2015-04-07'
      to                   = '2015-04-08'
      period2_selector     = "##{filter_name}_date_period_2"
      values_from_selector = "##{filter_name}_from"
      values_to_selector   = "##{filter_name}_to"
      page.find(period2_selector).set(true)
      page.find(values_from_selector).set(from)
      page.find(values_to_selector).set(to)
      apply_filters
      open_filters
      expect(page).to have_selector(period2_selector)

      expect(page.find(period2_selector)).to be_checked

      expect(page.find(values_from_selector).value).to eq(from)
      expect(page.find(values_to_selector).value).to eq(to)
    end
  end

#  context 'relations' do
#    let(:issue) { FactoryGirl.create(:issue) }
#
#    before(:each) do
#      issue
#      visit issues_path
#      wait_for_ajax
#      open_filters
#    end
#
#    it 'entity' do
#      filter = get_filter_by_type(:relation)
#      filter_name = filter.first
#      select_filter(filter_name)
#      autocomplete_css = "##{filter_name}_entities.ui-autocomplete-input"
#      expect(page).to have_css(autocomplete_css)
#      page.find("#div_values_#{filter_name} button").click
#      wait_for_ajax
#      page.find('.ui-menu-item', :text => issue.subject).click
#      wait_for_ajax
#      apply_filters
#      open_filters
#      expect(page.find(autocomplete_css).value).to eq(issue.subject)
#    end
#
#    it 'project' do
#      filter = get_filter_by_type(:relation)
#      filter_name = filter.first
#      select_filter(filter_name)
#      page.find("#operators_#{filter_name} option[value='=p']").select_option
#      autocomplete_css = "##{filter_name}_projects.ui-autocomplete-input"
#      expect(page).to have_css(autocomplete_css)
#      page.find("#div_values_#{filter_name} button").click
#      wait_for_ajax
#      page.find('.ui-menu-item', :text => issue.project.name).click
#      wait_for_ajax
#      apply_filters
#      open_filters
#      expect(page.find(autocomplete_css).value).to eq(issue.project.name)
#    end
#  end

  context 'custom formatting' do
    let(:issue1) { FactoryBot.create(:issue, estimated_hours: 5) }
    let(:issue2) { FactoryBot.create(:issue, estimated_hours: nil) }

    it 'can apply filters' do
      issue1; issue2
      with_easy_settings(show_easy_custom_formatting: true) do
        visit issues_path
        wait_for_ajax
        page.find('#easy-query-toggle-button-custom-formatting').click
        page.find('#add_scheme_select option.scheme-0').select_option
        wait_for_ajax
        wait_for_late_scripts
        page.find('#scheme-0add_filter_select option[value=\'estimated_hours\']').select_option
        page.find('#scheme-0values_estimated_hours_1').set('5')
        apply_filters
        expect(page).to have_css("#entity-#{issue1.id}.scheme-0")
        expect(page).to have_css("#entity-#{issue2.id}")
        expect(page).not_to have_css("#entity-#{issue2.id}.scheme-0")
      end
    end

    it 'duplicated filters' do
      issue1; issue2
      with_easy_settings(show_easy_custom_formatting: true) do
        visit issues_path(set_filter: '1', 'f': {"assigned_to_id": "!me"}, 'scheme-0': {"assigned_to_id": "me"})
        wait_for_ajax
        expect(page).to have_css("#entity-#{issue1.id}")
        expect(page).to have_css("#entity-#{issue2.id}")
      end
    end
  end

  context 'validations' do
    let(:project) { FactoryGirl.create(:project) }

    it 'inclusion' do
      visit issues_path(:set_filter => '1', :project_id => project)
      expect(page).not_to have_css('#errorExplanation')
    end
  end

  context 'list autocomplete' do
    let(:parent_issue) { FactoryGirl.create(:issue) }
    let(:issue) { FactoryGirl.create(:issue, :parent => parent_issue) }

    it 'parent id' do
      issue
      visit issues_path(:set_filter => '1', :parent_id => parent_issue.id.to_s)
      wait_for_ajax
      expect(page.find('.entities td.subject')).to have_content(issue.subject)
      open_filters
      expect(page).to have_selector('.filters-table #div_values_parent_id .entity-array span', text: parent_issue.subject)
    end
  end

  context 'search' do
    let!(:issue) { FactoryGirl.create(:issue, :subject => 'searched') }

    it 'blank' do
      visit issues_path(:set_filter => '1', :easy_query_q => '')
      expect(page).to have_css('.easy-query-heading')
      expect(page.find('.entities tbody')).to have_content('searched')
    end

    it 'token' do
      visit issues_path(:set_filter => '1', :easy_query_q => 'searched')
      expect(page).to have_css('.easy-query-heading')
      expect(page.find('.entities tbody')).to have_content('searched')
    end

    it 'grouped blank' do
      visit issues_path(:set_filter => '1', :easy_query_q => '', :group_by => 'project', :load_groups_opened => '1')
      wait_for_ajax
      expect(page).to have_css('.easy-query-heading')
      expect(page.find('.entities tbody')).to have_content('searched')
    end

    it 'grouped token' do
      visit issues_path(:set_filter => '1', :easy_query_q => 'searched', :group_by => 'project', :load_groups_opened => '1')
      wait_for_ajax
      expect(page).to have_css('.easy-query-heading')
      expect(page.find('.entities tbody')).to have_content('searched')
    end
  end

  context 'new easy query' do
    it 'loads available filters' do
      visit issues_path(:set_filter => '0')
      wait_for_ajax
      open_filters
      filter      = get_filter_by_type(:boolean)
      filter_name = filter.first
      select_filter(filter_name)
      values_selector = "#values_#{filter_name}_true"
      page.find(values_selector).set(true)
      apply_filters
      page.find('#easy-query-toggle-button-settings').click
      page.find('#filter_buttons .save-link').click
      wait_for_ajax
      expect(page).to have_css("#filters-table input#cb_#{filter_name}")
    end
  end

end
