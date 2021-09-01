require 'easy_extensions/spec_helper'

feature 'issue modal selector', js: true, logged: :admin, js_wait: :long do

  let(:project) { FactoryGirl.create(:project, number_of_issues: 1) }

  def open_related_issue_modal(issue)
    visit issue_path(issue)
    # show issue relations
    page.find('#sidebar .menu-more-container > a.menu-expander').click
    page.find("#sidebar .menu-more-container .menu-more-sidebar a[title='#{I18n.t(:title_new_issue_relation)}']").click
    # show modal selector
    page.find('#relation_issue_to_id').click
    wait_for_ajax(30)
    page.find('#easy_modal table.entities') # wait
  end

  it 'allows user to display modal selector after sorting added column' do
    open_related_issue_modal(project.issues.first)

    # add fixed version into columns
    within page.find('#easy_modal') do
      page.find('#modal_selectoreasy-query-toggle-button-settings').click
      wait_for_ajax
      page.find('#modal_selectorselected_columns').find('[value=subject]').select_option
      page.find('#modal_selector_move_column_left_button').click
      page.find('#modal_selectoravailable_columns').find('[value=fixed_version]').select_option
      page.find('#modal_selector_move_column_right_button').click
      page.find("#modal_selectorfilter_buttons input[type='submit']").click
      wait_for_ajax
      # set sorting
      page.find('table.entities thead th.fixed_version a').click
      wait_for_ajax
    end
    # close modal selector
    page.find('.ui-dialog-titlebar-close').click
    # open modal selector again
    page.find('#relation_issue_to_id').click
    wait_for_ajax(30)
    # page should show modal selector, so close button is present
    expect(page).to have_selector('.ui-dialog-titlebar-close', count: 1)
  end

  it 'adds project filter and preselects project when in project context' do
    open_related_issue_modal(project.issues.first)

    within page.find('#easy_modal') do
      page.find('#modal_selectoreasy-query-toggle-button-filters').click
      wait_for_ajax
      expect(page).to have_css('#modal_selectordiv_values_project_id')
      expect(page.find('#modal_selectordiv_values_project_id .entity-array > span')).to have_text(project.name)
    end
  end

  scenario 'load groups checkbox after update filters' do
    with_easy_settings(:easy_issue_query_grouped_by => 'project', :easy_issue_query_load_groups_opened => '1') do
      open_related_issue_modal(project.issues.first)

      within page.find('#easy_modal') do
        expect(page).to have_css("input[type='checkbox']", :count => 1)

        page.find('.settings').click
        execute_script('$("#modal_selectorfilter_buttons")[0].scrollIntoView();')
        page.find("#modal_selectorfilter_buttons").click
        wait_for_ajax
        expect(page).to have_css("input[type='checkbox']", :count => 1)
      end
    end
  end

  scenario 'parent issue modal selector' do
    visit_issue_with_edit_open(project.issues.first)
    page.find('#issue_parent_issue_id').click
    wait_for_ajax
    expect(page).to have_css('#issue_parent_issue_id-content-container')
  end

  context 'versions' do
    let(:version) { FactoryGirl.create(:version, description: 'test', project: project) }
    let(:project) { FactoryGirl.create(:project) }
    let(:xsettings) { HashWithIndifferentAccess.new(entity_type: 'Version', entity_attribute: 'link_with_name') }
    let(:custom_field) { FactoryGirl.create(:project_custom_field, field_format: 'easy_lookup', settings: xsettings, is_for_all: true) }

    scenario 'block columns' do
      version
      custom_field
      visit settings_project_path(project)
      wait_for_ajax
      page.find('.easy-lookup-values').click
      wait_for_ajax
      expect(page.find('#modal-selector-entities')).to have_content(version.description)
    end
  end

  context 'using search' do
    let(:related_issue) { FactoryGirl.create(:issue, project: project) }
    let(:issue2) { FactoryGirl.create(:issue, :subject => 'AAA test', project: project) }
    around(:each) do |ex|
      with_easy_settings(easy_issue_query_list_default_columns: ['project', 'subject']) do
        ex.run
      end
    end
    before(:each) { open_related_issue_modal(project.issues.first) }

    scenario 'sort results' do
      issue2
      within page.find('#easy_modal') do
        page.find('#easy_query_q').set('test')
        page.find('#easy_query_q').native.send_keys(:return)
        wait_for_ajax
        wait_for_late_scripts
        # sort by subject
        page.find('table.entities thead th.subject a').click
        wait_for_ajax
        expect(page.find('table.entities tbody tr:first-child td.subject').text).to include('AAA')
      end
    end

    scenario 'found' do
      within page.find('#easy_modal') do
        page.find('#easy_query_q').set(related_issue.id)
        page.find('#easy_query_q').native.send_keys(:return)
        wait_for_ajax
        expect(page).to have_selector('table.entities tbody tr', :count => 1)
        expect(page).to have_content(related_issue.subject)
      end
    end

    scenario 'not found' do
      within page.find('#easy_modal') do
        page.find('#easy_query_q').set(project.issues.first.id + 222)
        page.find('#easy_query_q').native.send_keys(:return)
        wait_for_ajax
        expect(page).not_to have_selector('table.entities tbody tr')
      end
    end

    scenario 'remember query params' do
      within page.find('#easy_modal') do
        page.find('.settings').click
        expect(page).to have_css("#modal_selectoravailable_columns option[value='author']")
        page.execute_script("$(\"#modal_selectoravailable_columns option[value=\'author\']\").attr('selected', 'selected')")
        page.find('#modal_selector_move_column_right_button').click
        page.find("input[type='submit']").click
        wait_for_ajax
        expect(page).to have_css('th.author', :count => 1)
        page.find('#easy_query_q').set(related_issue.id)
        page.find('#easy_query_q').native.send_keys(:return)
        wait_for_ajax
        expect(page).to have_selector('table.entities tbody tr', :count => 1)
        expect(page).to have_content(related_issue.subject)
        expect(page).to have_css('th.author', :count => 1)
      end
    end
  end
end
