FactoryGirl.define do
  factory :easy_agile_board_query, parent: :easy_query, class: 'EasyAgileBoardQuery' do
    name { 'TestAgileBoardQuery' }
    project { FactoryGirl.create(:project, add_modules: %w(easy_scrum_board easy_kanban_board)) }
  end
end
