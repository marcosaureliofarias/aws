require 'easy_extensions/spec_helper'

RSpec.feature 'Resource', js: true, logged: :admin do

  let(:project) { FactoryGirl.create(:project, number_of_members: 2, number_of_issues: 3, add_modules: ['easy_gantt', 'easy_gantt_resources']) }

  around(:each) do |example|
    with_settings(rest_api_enabled: 1) { example.run }
  end

  def clear_history
    script= <<-EOF
      (function(){
        ysy.history.clear();
      })();
    EOF
    page.execute_script(script)
  end

  scenario 'without enable rest-api' do
    with_settings(rest_api_enabled: 0) do
      visit easy_gantt_resources_path
      expect(page).to have_text(I18n.t('easy_gantt.errors.no_rest_api'))
    end
  end

  context 'global' do

    scenario 'load resources' do
      visit easy_gantt_resources_path
      wait_for_ajax
      gantt_grid_data = page.find('.gantt_grid_data')
      expect(gantt_grid_data).to have_selector('a', text: User.current.to_s, count: 1)
      legend = page.find('#easy_gantt_footer_legend')
      expect(legend).to have_text(I18n.t('easy_gantt_resources.legend.day_over_allocation'))
      page.find('#button_day_zoom').click
      expect(legend).not_to have_text(I18n.t('easy_gantt_resources.legend.some_allocations'))
      page.find('#button_week_zoom').click
      expect(legend).to have_text(I18n.t('easy_gantt_resources.legend.some_allocations'))
      clear_history
    end

    context 'save resources' do
      let(:project) { FactoryBot.create(:project, number_of_members: 1, number_of_issues: 0, add_modules: ['easy_gantt', 'easy_gantt_resources']) }
      let(:template) { FactoryBot.create(:project, :template, number_of_members: 1, number_of_issues: 0, add_modules: ['easy_gantt', 'easy_gantt_resources']) }
      let(:issue) { FactoryBot.create(:issue, project: project, assigned_to: project.members.first.user, author: project.members.first.user, estimated_hours: 10) }
      let(:template_issue) { FactoryBot.create(:issue, project: template, assigned_to: template.members.first.user, author: template.members.first.user, estimated_hours: 10) }

      context 'global context' do
        scenario 'project' do
          user_id = issue.assigned_to_id
          visit easy_gantt_resources_path
          wait_for_ajax
          page.find("div[task_id='a#{user_id}'] .gantt_tree_expander").click
          wait_for_ajax
          page.find("div[task_id='#{issue.id}'].gantt_task_line").drag_to(page.find(".gantt_link_control.task_right"))
          page.find("#button_save").click
          wait_for_ajax
          expect(page).to have_css("#button_save.disabled")
        end

        scenario 'template' do
          user_id = template_issue.assigned_to_id
          visit easy_gantt_resources_path
          wait_for_ajax
          page.find("div[task_id='a#{user_id}'] .gantt_tree_expander").click
          wait_for_ajax
          expect(page).not_to have_css("div[task_id='#{template_issue.id}'].gantt_task_line")
        end
      end

      context 'project context' do
        scenario 'project' do
          issue
          visit easy_gantt_path(project_id: project.id, gantt_type: 'rm')
          wait_for_ajax
          page.find("div[task_id='#{issue.id}'].gantt_task_line").drag_to(page.find(".gantt_link_control.task_right"))
          expect do
            page.find("#button_save").click
            wait_for_ajax
            expect(page).to have_css("#button_save.disabled")
          end.to change(EasyGanttResource, :count)
        end

        scenario 'template' do
          template_issue
          visit easy_gantt_path(project_id: template.id, gantt_type: 'rm')
          wait_for_ajax
          page.find("div[task_id='#{template_issue.id}'].gantt_task_line").drag_to(page.find(".gantt_link_control.task_right"))
          expect do
            page.find("#button_save").click
            wait_for_ajax
            expect(page).to have_css("#button_save.disabled")
            expect(page).to have_css(".flash.error") # project is template
          end.not_to change(EasyGanttResource, :count)
        end
      end
    end

  end

  context 'project' do

    scenario 'load resources' do
      visit easy_gantt_path(project, gantt_type: 'rm')
      wait_for_ajax
      expect(page).to have_css("#easy_gantt.resource_management")
      legend = page.find('#easy_gantt_footer_legend')
      expect(legend).to have_text(I18n.t('easy_gantt_resources.legend.day_over_allocation'))
      page.find('#button_day_zoom').click
      expect(legend).not_to have_text(I18n.t('easy_gantt_resources.legend.some_allocations'))
      page.find('#button_week_zoom').click
      expect(legend).to have_text(I18n.t('easy_gantt_resources.legend.some_allocations'))
      clear_history
    end

  end

end
