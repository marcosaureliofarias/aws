require File.expand_path('../../../../easyproject/easy_plugins/easy_extensions/test/spec/spec_helper', __FILE__)

RSpec.feature 'Project milestones', js: true, logged: :admin do

  let!(:project) { FactoryGirl.create(:project, add_modules: ['easy_gantt'], ) }
  let!(:milestone1) { FactoryGirl.create(:version, project_id: project.id,due_date:Date.today - 2.days) }
  let!(:milestone2) { FactoryGirl.create(:version, project_id: project.id,due_date:Date.today + 2.days) }
  let!(:issue) { FactoryGirl.create(:issue, project_id: project.id,start_date:Date.today - 3.days,due_date:Date.today + 3.days) }
  #let!(:issue2) { FactoryGirl.create(:issue) }
  #let!(:relation) { FactoryGirl.create(:issue_relation, source_id:issue1.id, target_id:issue2.id) }

  around(:each) do |example|
    with_settings(rest_api_enabled: 1) do
      with_easy_settings(easy_gantt_show_project_milestones: true) do
        example.run
      end
    end
  end


  [false,true].each do |pipeline|
    it "should display 2 milestones #{'(pipeline)' if pipeline}" do
      visit easy_gantt_path
      wait_for_ajax
      cont = page.find('.gantt-project-milestones')
      expect(cont).to have_css('.gantt-project-milestone', count: 2)
      page.find('.gantt_open').click
      expect(page).to have_text(milestone1.name)
      expect(page).not_to have_css('.gantt-project-milestones')
    end
  end

end
