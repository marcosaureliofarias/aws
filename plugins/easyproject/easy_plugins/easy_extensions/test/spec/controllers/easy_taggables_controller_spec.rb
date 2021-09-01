require 'easy_extensions/spec_helper'

describe EasyTaggablesController, logged: :admin do
  let(:issue) { FactoryBot.create(:issue) }
  let(:project) { FactoryBot.create(:project) }

  it 'add tags to an issue' do
    expect {
      get :save_entity, params: {id: issue.id, klass: 'Issue', format: 'json', entity: {tag_list: ["planing"]}}
      expect(response).to be_successful
    }.to change(Journal, :count).by(1)
  end

  it 'add tags to a project' do
    expect {
      get :save_entity, params: {id: project.id, klass: 'Project', format: 'json', entity: {tag_list: ["planing"]}}
      expect(response).to be_successful
    }.to change(Journal, :count).by(1)
  end

end
