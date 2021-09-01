require 'easy_extensions/spec_helper'

feature 'easy knowledge', logged: :admin, js: true do
  let(:project) { FactoryGirl.create(:project, enabled_module_names: ['easy_knowledge']) }
  let(:easy_knowledge_story) { FactoryGirl.create(:easy_knowledge_story) }
  let(:easy_knowledge_assigned_story) { FactoryGirl.create(:easy_knowledge_assigned_story, easy_knowledge_story: easy_knowledge_story, entity: project, read_date: nil) }

  def expand_sidebar_menu
    page.find('#sidebar .menu-more-container > a.menu-expander').click
  end

  scenario 'test sidebar modal selectors' do
    easy_knowledge_assigned_story
    visit easy_knowledge_story_path(easy_knowledge_story, project_id: project)
    expand_sidebar_menu
    page.all('#menu-more-8 a[id*="lookup_trigger"]').each do |link|
      link.click
      wait_for_ajax
      expect(page).to have_selector('#easy_modal #modal_selector')
      page.all('.ui-dialog-buttonset button')[1].click
    end
  end
end
