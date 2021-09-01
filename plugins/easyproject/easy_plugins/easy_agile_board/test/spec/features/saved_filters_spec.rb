require 'easy_extensions/spec_helper'

feature 'saved filters', logged: :admin do

  let!(:project) { FactoryGirl.create(:project, number_of_issues: 0, add_modules: ['easy_scrum_board', 'easy_kanban_board']) }
  let!(:sprint) { FactoryGirl.create(:easy_sprint, project: project) }
  let!(:easy_query) { FactoryGirl.create(:easy_agile_board_query, project_id: nil, visibility: EasyQuery::VISIBILITY_PUBLIC) }
  let!(:epzm) { EasyPageZoneModule.create(easy_pages_id: 1, easy_page_available_zones_id: 1,
      easy_page_available_modules_id: 10, user_id: User.current.id,
      settings: {'queries' => ['easy_agile_board_query'], 'saved_public_queries' => 'true'}) }

  it 'shows saved agile board query' do
    visit root_path
    expect(page).to have_css("#module_inside_#{epzm.id}")
    expect(page).to have_content(easy_query.name)
  end

end
