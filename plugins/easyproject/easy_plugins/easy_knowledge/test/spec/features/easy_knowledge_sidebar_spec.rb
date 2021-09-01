require 'easy_extensions/spec_helper'

feature 'easy knowledge categories', :logged => :admin, :js => true do
  let(:easy_knowledge_story) { FactoryGirl.create(:easy_knowledge_story) }
  let(:easy_knowledge_assigned_story) { FactoryGirl.create(:easy_knowledge_assigned_story,
      :easy_knowledge_story => easy_knowledge_story, :entity => User.current, :read_date => nil) }

  scenario 'mark all as read' do
    easy_knowledge_assigned_story
    visit root_path
    page.execute_script('$("#easy_knowledge_toolbar_trigger").trigger("click")')
    wait_for_ajax
    page.execute_script('$(".mark-all-eks-as-read > a").trigger("click")')
    wait_for_ajax
    expect(page).not_to have_css('.mark-all-eks-as-read')
    expect(page).not_to have_css('.upper.easy-knowledge-indicator')
  end
end
