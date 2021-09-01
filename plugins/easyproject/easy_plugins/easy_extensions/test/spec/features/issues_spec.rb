require 'easy_extensions/spec_helper'

feature 'issues', js: true, logged: :admin do

  let(:project) { FactoryGirl.create(:project) }
  let(:issue) { project.issues.last }

  def remove_subject_validation
    expect(page).to have_css('#issue_subject')
    page.execute_script("$('#issue_subject').prop('required', false)")
  end

  it 'update issue and check journal details' do
    issue.init_journal(User.current)
    issue.attributes = { :status_id => FactoryGirl.create(:issue_status, :closed) }
    issue.save!

    visit issue_path(issue)
    page.find("a[data-tab-id=tab-history]").click
    expect(page).to have_css('.journal-details-container .details li', :count => 1)
  end

  def check_created_on_column
    visit issues_path(:set_filter => '1', :show_sum_row => '1', :column_names => ['created_on'])
    expect(page).to have_css('.issues')
  end

  it 'update issue and check journal details' do
    issue
    with_easy_settings(:issue_created_on_date_format => 'date') { check_created_on_column }
    with_easy_settings(:issue_created_on_date_format => 'datetime') { check_created_on_column }
  end

  it 'new issue without project' do
    visit new_issue_path
    remove_subject_validation
    page.find("input[name='commit']").click
    expect(page).to have_css('#errorExplanation')
  end

  if Rys::Feature.active?('email_field_autocomplete')
    it 'autocomplete email field' do
      visit edit_issue_path(issue)

      fill_in 'issue_easy_email_to', with: issue.author.mail

      page.execute_script %Q{ $('#issue_easy_email_to').trigger("focus") }
      page.execute_script %Q{ $('#issue_easy_email_to').trigger("keydown") }
      selector = %{ul.ui-autocomplete li.ui-menu-item:contains("#{issue.author.mail}")}

      expect(page).to have_selector('ul.ui-autocomplete li.ui-menu-item')
      page.execute_script %{ $('#{selector}').trigger('mouseenter').click() }
    end
  end

  it 'new issue project context' do
    visit new_issue_path(:project_id => project)
    page.find('#issue_subject').set('test')
    page.find("input[name='commit']").click
    expect(page).to have_css('.flash.notice')
  end

  it 'new issue select project with activity' do
    with_easy_settings({ :project_fixed_activity => true }, project) do
      visit new_issue_path
      page.find('#issue_subject').set('test')
      page.execute_script "setEasyAutoCompleteValue('issue_project_id', '#{project.id}', '#{project.name}')"
      wait_for_ajax
      expect(page).to have_css('.timeentry-activities input', :count => project.project_time_entry_activities.count)
      page.find("#radio-timeentry-issue-#{project.project_time_entry_activities.first.id}").set(true)
      page.find("input[name='commit']").click
      expect(page).to have_css('.flash.notice')
    end
  end

  it 'new issue hide project 1' do
    visit new_issue_path
    remove_subject_validation
    page.find("input[name='commit']").click
    expect(page).to have_css('#errorExplanation')
  end

  it 'new issue hide project 2' do
    visit new_issue_path
    remove_subject_validation
    page.find("input[name='commit']").click
    expect(page).to have_css('#errorExplanation')
    page.execute_script "setEasyAutoCompleteValue('issue_project_id', '#{project.id}', '#{project.name}')"
    wait_for_ajax
    page.find("input[name='commit']").click
    expect(page).to have_css('#errorExplanation')
    expect(page).not_to have_css('#project_id') # hidden
  end

  it 'sidebar spent time' do
    visit issue_path(issue)
    sidebar_closed = page.has_css?('.nosidebar')
    if sidebar_closed
      page.find(".sidebar-control > a").click
    end
    page.find('#easy_page_layout_service_box .spent-time a').click
    expect(page).to have_css('.menu-project-menu a.time-entries.selected')
  end

  it 'inline edit' do
    visit issue_path(issue)
    page.execute_script("$('#issue-detail-attributes .status .icon-edit').css('opacity', 1);")
    page.find('#issue-detail-attributes .status .icon-edit').click()
    expect(page).to have_css('.editableform .editable-buttons')
  end

  context 'spent time links' do
    let(:issue) { FactoryBot.create(:issue) }
    let(:issue2) { FactoryBot.create(:issue, parent: issue) }
    let!(:time_entry) { FactoryBot.create(:time_entry, issue: issue, hours: 3) }
    let!(:time_entry2) { FactoryBot.create(:time_entry, issue: issue2, hours: 3) }

    def get_link(idx)
      visit issue_path(issue)
      wait_for_ajax
      page.find('#issue_detail_header .more-attributes-toggler').click
      spent_time = page.find('.easy-entity-details-header-attributes .spent-time')
      links      = spent_time.all('a')
      expect(links.size).to eq(2)
      links[idx]
    end

    it 'only issue' do
      get_link(0).click
      expect(page).to have_css(".entities tbody tr", count: 1)
    end

    it 'total' do
      get_link(1).click
      expect(page).to have_css(".entities tbody tr", count: 2)
    end
  end

  context 'journal details' do
    let(:cf) { FactoryGirl.create(:issue_custom_field, :is_for_all => true,
                                  :field_format                    => 'link', :format_store => { :url_pattern => 'http://127.0.0.1/issue?id=%id%' }) }
    let(:journal) { Journal.create!(:journalized => issue, :user => User.current) }
    let(:detail) { JournalDetail.create!(:journal_id => journal.id, :property => 'cf', :prop_key => cf.id, :value => 'LinkedDetail') }

    it 'journal with url' do
      tracker               = issue.tracker
      tracker.custom_fields = [cf]
      tracker.save
      detail
      issue.reload
      visit issue_path(issue)
      wait_for_ajax
      page.find("a[data-tab-id=tab-history]").click
      expect(page).to have_content(detail.value)
      expect(page).to have_css("a[href='http://127.0.0.1/issue?id=#{issue.id}']")
    end

#    context 'quotes' do
#      before(:each) { Journal.create!(:journalized => issue, :user => User.current, :notes => 'xxx') }
#
#      ['textile', 'HTML'].each do |format|
#        it format do
#          with_settings({'text_formatting' => format}) do
#            visit issue_path(issue)
#            wait_for_ajax
#            within(page.find('.journal-tools')) do
#              page.find('a.icon-settings').click
#              page.find('a.icon-comment').click
#            end
#            wait_for_ajax
#            expect(page.find('#issue_notes', visible: false).value).to include('xxx')
#            page.find('.form-actions a.button', text: /#{I18n.t(:button_cancel)}/i ).click
#            page.find('.journal-tools a.icon-comment').click
#            expect(page.find('#issue_notes', visible: false).value).to include('xxx')
#          end
#        end
#      end
#    end
  end

  context 'hours format' do
    let(:issue2) { FactoryGirl.create(:issue, :estimated_hours => 1.5) }
    let!(:time_entry) { FactoryGirl.create(:time_entry, :hours => 1.5, :issue => issue2) }

    it 'estimated hours and spent time' do
      issue2.reload
      with_user_pref('hours_format' => 'long') do
        visit issue_path(issue2)
        wait_for_ajax
        page.find('#issue_detail_header .more-attributes-toggler').click
        spent_time = page.find('.easy-entity-details-header-attributes .spent-time')
        expect(spent_time).to have_content('1')
        expect(spent_time).to have_content('30')
        est_hours = page.find('.easy-entity-details-header-attributes .estimated-hours')
        expect(est_hours).to have_content('1')
        expect(est_hours).to have_content('30')
      end

      page.execute_script 'localStorage.clear();'

      with_user_pref('hours_format' => 'short') do
        visit issue_path(issue2)
        page.find('#issue_detail_header .more-attributes-toggler').click
        spent_time = page.find('.easy-entity-details-header-attributes .spent-time')
        expect(spent_time).to have_content('1')
        expect(spent_time).to have_content('5')
        est_hours = page.find('.easy-entity-details-header-attributes .estimated-hours')
        expect(est_hours).to have_content('1')
        expect(est_hours).to have_content('5')
      end

    end
  end

  context 'bulk update' do
    let!(:issue_with_due_date) { FactoryGirl.create(:issue, :due_date => Date.today, :project => project) }
    let!(:issue_without_due_date) { FactoryGirl.create(:issue, :due_date => nil, :project => project) }

    it 'due date is blank' do
      project.reload
      original_due_dates = project.issues.reorder(:id).pluck(:due_date)
      visit bulk_edit_issues_path(:ids => project.issues.pluck(:id))
      page.find('#issue_due_date_type_change_by').set(true)
      wait_for_ajax
      page.find('#issue_due_date_change_by').set('1')
      page.find("input[name='commit']").click
      expect(page).to have_css('.flash.notice')
      project.reload
      new_due_dates = project.issues.reorder(:id).pluck(:due_date)
      expect(original_due_dates.map { |x| x ? (x + 1.day) : nil }).to eq(new_due_dates)
    end
  end

  [[true, nil, true], [false, nil, false], [true, '0', false], [false, '1', true], [true, '0', false], [true, '1', true]].each do |settings|
    it "private notes #{settings}" do
      with_easy_settings(:issue_private_note_as_default => settings[0]) do
        visit edit_issue_path(issue, settings[1].nil? ? {} : { :issue => { :private_notes => settings[1] } })
        wait_for_ajax
        element = page.find("input#issue_private_notes")
        settings[2] ? expect(element).to(be_checked) : expect(element).not_to(be_checked)
        # fill_in_ckeditor(1, :context => '#issue_edit_textarea', :with => 'test')
        page.find('#issue_notes').set('test')
        page.find("input[name='commit']").click
        settings[2] ? expect(page).to(have_css('.private')) : expect(page).not_to(have_css('.private'))
      end
    end
  end

  context 'datepickers' do
#    it 'edit duedate' do
#      with_easy_settings(:html5_dates => false) do
#        visit issue_path(issue)
#        wait_for_ajax
#        page.find('#issue-detail-attributes .due-date .icon-edit', :visible => false).click
#        expect(page).to have_css('.editableform .editable-buttons')
#        page.find('.editableform .editable-buttons .editable-cancel').click
#      end
#    end

    it 'open repeating and edit period' do
      with_easy_settings(:html5_dates => false) do
        visit edit_issue_path(issue)
        page.find('.issue-edit-hidden-attributes').click
        wait_for_ajax
        page.find("#issue_easy_repeat_settings_simple_period option[value='custom']").select_option
        wait_for_ajax
        page.first('#easy_section_repeating_options .splitcontentright fieldset > legend').click
        page.find('#issue_easy_next_start + button').click
        expect(page).to have_css('.ui-datepicker-calendar')
        page.find('.ui-datepicker-close').click
      end
    end
  end

  context 'issue custom fields' do
    let!(:custom_field) { FactoryGirl.create(:issue_custom_field, :trackers => [project.trackers.last]) }

    it 'new form refresh custom fields', :js_wait => :long do
      visit new_issue_path(:issue => { :tracker_id => project.trackers.first.id.to_s, :project_id => project.id.to_s })
      wait_for_ajax
      last_tracker = project.trackers.last
      expect(page).not_to have_css("#issue_custom_field_values_#{last_tracker.id}_")
      tracker_select = page.find('#issue_tracker_id')
      tracker_select.find("[value='#{project.trackers.last.id}']").select_option
      wait_for_ajax
      expect(page).to have_css("#issue_custom_field_values_#{custom_field.id}_")
    end
  end

  context 'issue with an external watcher' do
    let(:external_user) { FactoryGirl.create(:user) }
    let!(:role) { FactoryGirl.create(:role, :name => 'client', :issues_visibility => 'own', :permissions => [:view_issues]) }
    let!(:member) { FactoryGirl.create(:member, :project => project, :principal => external_user, :roles => [role]) }
    let!(:watched_issue) { FactoryGirl.create(:issue, :project => project, :watchers => [external_user]) }

    it 'does not send notifications about invisible relations' do
      ActionMailer::Base.deliveries = []
      visit issue_path(watched_issue)

      page.find('.menu-more-container .menu-expander').click
      page.find(".menu-more-container .issue-copy[title='#{I18n.t(:sidebar_issue_button_copy)}']").click
      wait_for_ajax
      page.find('input#issue_subject').set('copied')
      page.uncheck("issue_watcher_user_ids_#{external_user.id}")
      page.first('input[type="submit"]').click

      expect(ActionMailer::Base.deliveries.any? { |mail| mail.bcc.include?(external_user.mail) }).to eq(false)
    end
  end

  context 'copy relations', :js_wait => :long, :slow => true do
    let!(:project) { FactoryGirl.create(:project, :number_of_issues => 0) }
    let!(:project2) { FactoryGirl.create(:project, :number_of_issues => 2) }
    let!(:root_issue) { FactoryGirl.create(:issue, :project => project) }
    let!(:child_issue) { FactoryGirl.create(:issue, :project => project, :parent => root_issue) }
    let!(:child_issue2) { FactoryGirl.create(:issue, :project => project, :parent => root_issue) }
    let!(:leaf_issue) { FactoryGirl.create(:issue, :project => project, :parent => child_issue2) }
    let!(:relation1) { FactoryGirl.create(:issue_relation, :issue_from => child_issue, :issue_to => child_issue2) }
    let!(:relation2) { FactoryGirl.create(:issue_relation, :issue_from => child_issue, :issue_to => leaf_issue) }
    let(:relation3) { FactoryGirl.create(:issue_relation, :issue_from => child_issue, :issue_to => project2.issues.first) }
    let(:relation4) { FactoryGirl.create(:issue_relation, :issue_from => project2.issues.last, :issue_to => child_issue) }

    it 'copy relations' do
      with_settings(:cross_project_issue_relations => '1') do
        relation3; relation4
        visit issue_path(root_issue)
        actions = page.find('.issue_actions')
        actions.find('.menu-expander').click
        actions.find(".issue-copy[title='#{I18n.t(:sidebar_issue_button_copy)}']").click
        expect(page.find("#copy_subtasks")).to be_checked
        expect(page.find("#copy_relations")).to be_checked
        page.find(".issue_submit_buttons input[name='commit']").click

        expect(page).to have_css('.issue-relations tr', :count => 1)
        copied_from = page.find('.issue-relations tr')
        expect(copied_from).to have_content(root_issue.subject)
        expect(copied_from).to have_content(I18n.t(:label_copied_from))

        visit issue_path(child_issue)
        expect(page).to have_css('.issue-relations tr', :count => 5)
        relations = page.find('.issue-relations')
        expect(relations).to have_content(I18n.t(:label_copied_to))
        [child_issue2, leaf_issue, project2.issues.first, project2.issues.last].map(&:id).each do |id|
          expect(relations).to have_css("tr.issue-#{id}")
        end

        copied_child_issue = child_issue.relations.detect { |x| x.relation_type == 'copied_to' }.issue_to
        visit issue_path(copied_child_issue)
        expect(page).to have_css('.issue-relations tr', :count => 5)
        relations = page.find('.issue-relations')
        expect(relations).to have_content(I18n.t(:label_copied_from))
        [project2.issues.first, project2.issues.last].map(&:id).each do |id|
          expect(relations).to have_css("tr.issue-#{id}")
        end
        [child_issue2, leaf_issue].map(&:id).each do |id|
          expect(relations).not_to have_css("tr.issue-#{id}")
        end

        copied_child_issue2 = child_issue2.relations.detect { |x| x.relation_type == 'copied_to' }.issue_to
        copied_leaf_issue   = leaf_issue.relations.detect { |x| x.relation_type == 'copied_to' }.issue_to
        [copied_child_issue2, copied_leaf_issue].map(&:id).each do |id|
          expect(relations).to have_css("tr.issue-#{id}")
        end

      end
    end

    it 'copy relations on a leaf' do
      with_settings(:cross_project_issue_relations => '1') do
        visit issue_path(leaf_issue)
        actions = page.find('.issue_actions')
        actions.find('.menu-expander').click
        actions.find(".issue-copy[title='#{I18n.t(:sidebar_issue_button_copy)}']").click
        expect(page).not_to have_css("#copy_subtasks")
        expect(page.find("#copy_relations")).to be_checked
        page.find(".issue_submit_buttons input[name='commit']").click

        copied_leaf_issue = leaf_issue.relations.detect { |x| x.relation_type == 'copied_to' }.issue_to
        visit issue_path(copied_leaf_issue)
        relations = page.find('.issue-relations')

        expect(relations).to have_css("tr.issue-#{leaf_issue.id}")
      end
    end
  end

  context 'custom field values' do
    let(:tracker) { FactoryGirl.create(:tracker) }
    let(:cf1) { FactoryGirl.create(:issue_custom_field, :is_for_all => false, :project_ids => [project.id], :tracker_ids => [tracker.id]) }
    let(:cf2) { FactoryGirl.create(:issue_custom_field, :is_for_all => false, :project_ids => [project2.id], :tracker_ids => [tracker.id]) }
    let(:project) { FactoryGirl.create(:project, :number_of_issues => 0, :trackers => tracker) }
    let(:project2) { FactoryGirl.create(:project, :number_of_issues => 0, :trackers => tracker) }
    let(:issue) { FactoryGirl.create(:issue, :project => project, :tracker => tracker) }

    it 'visibility after project change' do
      with_easy_settings(:display_project_field_on_issue_detail => true) do
        cf1; cf2
        visit project_copy_issue_path(project, :copy_from => issue)
        expect(page.find('#custom_fields_container')).to have_content(cf1.name)
        page.execute_script "setEasyAutoCompleteValue('issue_project_id', '#{project2.id}', '#{project2.name}')"
        wait_for_ajax
        expect(page.find('#custom_fields_container')).not_to have_content(cf1.name)
        expect(page.find('#custom_fields_container')).to have_content(cf2.name)
      end
    end
  end

  context 'relations form' do
    let(:issue) { FactoryGirl.create(:issue) }
    it 'initialize form actions' do
      visit issue_path(issue)
      page.find('.issue_actions .menu-expander').click
      page.find('.issue_actions .icon-relation').click
      expect(page).to have_css('#new-relation-form')
      expect(page).to have_css('#new-relation-form .button-positive')
    end
  end
end
