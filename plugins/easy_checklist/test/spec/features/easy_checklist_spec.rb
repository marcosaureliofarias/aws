require 'easy_extensions/spec_helper'

feature 'Easy checklist', :logged => :admin, :js => true, :js_wait => :long do

  let!(:project) { FactoryGirl.create(:project, :add_modules => ['easy_checklists'], :members => [User.current]) }
  let(:issue) { FactoryGirl.create(:issue, :project => project) }

  scenario 'New checklist from new issue form' do
    visit new_project_issue_path(project)
    fill_in('issue_subject', with: 'issue1')

    expect{
      fill_checklist_on_new_form_and_submit
    }.to change{
      EasyChecklist.count
    }.by(1)

    expect(Issue.last.easy_checklists.count).to eq 1
  end

  scenario 'New checklist from issue detail' do
    visit issue_path(issue)

    expect{
      fill_checklist_on_detail_form_and_submit
    }.to change{
      issue.reload.easy_checklists.count
    }.by(1)
  end

  scenario 'Check/Uncheck checklist item from issue detail' do
    visit issue_path(issue)

    fill_checklist_on_detail_form_and_submit

    easy_checklist = issue.easy_checklists.first

    expect{
      add_checklist_item_on_detail(easy_checklist)
    }.to change{
      easy_checklist.easy_checklist_items.count
    }.by(1)

    expect{
      check_checklist_item(easy_checklist)
    }.to change{
      easy_checklist.easy_checklist_items.first.reload.done
    }.to true

    expect{
      uncheck_checklist_item(easy_checklist)
    }.to change{
      easy_checklist.easy_checklist_items.first.reload.done
    }.to false
  end

  scenario 'Create new checklist template' do
    visit new_easy_checklist_path

    expect {
      fill_checklist_template_and_submit
    }.to change{
      project.easy_checklist_templates.count
    }.by(1)
  end

  scenario 'Apply checklist template to issue detail' do
    visit new_easy_checklist_path
    fill_checklist_template_and_submit

    visit issue_path(issue)

    easy_checklists_count = EasyChecklist.count

    expect{
      add_checklist_template_on_detail
    }.to change{
      issue.easy_checklists.count
    }.by(1)

    expect(EasyChecklist.count).to eq(easy_checklists_count + 1)
  end

  scenario 'Remove checklist from issue detail' do
    visit issue_path(issue)

    fill_checklist_on_detail_form_and_submit
    checklist = issue.easy_checklists.first
    checklist_items_container = "#easy_checklist#{checklist.id}_items_container"
    expect(page).to have_css(checklist_items_container)
    remove_checklist_from_detail(checklist)
    expect(page).not_to have_css(checklist_items_container)
  end

  def fill_checklist_on_new_form_and_submit
    page.find('#easy_checklist_form_container .button').click

    fill_all_checklists_fields

    page.find('.issue_submit_buttons .button-positive').click
  end

  def fill_checklist_on_detail_form_and_submit
    find('h3', :text => I18n.t(:label_easy_checklist)).click
    page.execute_script('$("#easy_checklist_form_container").toggle();')

    fill_all_checklists_fields

    find('#easy_checklist_form_container .button-positive').click
    wait_for_ajax
  end

  def fill_checklist_template_and_submit
    find('.easy_checklist_add_item').click
    find('.easy_checklist_add_item').click
    fill_all_checklists_fields
    # set project
    find('#easy_checklist_project_ids input[type=checkbox]').set(true)
    find('.form-actions input[type=submit]').click
  end

  def add_checklist_item_on_detail(easy_checklist)
    checklist_id = "#easy_checklist#{easy_checklist.id}"

    find("#{checklist_id} .easy-checklist-add-item").click
    find("#{checklist_id} #easy_checklist_item_subject").set("value for checklist")
    find("#{checklist_id}_item_form .icon-save").click
    wait_for_ajax
  end

  def check_checklist_item(easy_checklist)
    find("#easy_checklist_done#{easy_checklist.easy_checklist_items.first.id}").set(true)
    wait_for_ajax
  end

  def uncheck_checklist_item(easy_checklist)
    find("#easy_checklist_done#{easy_checklist.easy_checklist_items.first.id}").set(false)
    wait_for_ajax
  end

  def add_checklist_template_on_detail
    find('h3', :text => I18n.t(:label_easy_checklist)).click
    page.execute_script('$("#easy_checklist_form_container").toggle();')
    find('#easy_checklist_template_id').find(:xpath, 'option[2]').select_option
    find('#easy_checklist_add_template .button-positive').click
    wait_for_ajax
  end

  def remove_checklist_from_detail(easy_checklist)
    checklist_id = "#easy_checklist#{easy_checklist.id}"

    find("#{checklist_id} a[data-method=delete]").click
    #accept_confirm
    wait_for_ajax
  end

  def fill_all_checklists_fields(id = "#easy_checklist_form_container")
    all(:css, "#{id} input[type=text]").each do |e|
      e.set("value for checklist")
    end
  end

end
