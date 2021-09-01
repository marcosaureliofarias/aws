require 'easy_extensions/spec_helper'

describe JournalsController, :logged => :admin do
  let!(:project) { FactoryGirl.create(:project, :members => [User.current]) }
  let!(:journal) { FactoryGirl.create(:journal) }

  it 'renders 406 header when HTML access to edit journal' do
    project.issues.first.journals << journal

    get :edit, :params => { :id => journal.id, :format => :html }
    expect(response).to have_http_status(406)

    get :edit, :params => { :id => journal.id }, :xhr => true
    expect(response).to be_successful
  end

  it 'atom' do
    get :index
    expect(response).to be_successful
  end

  it 'atom + set filter' do
    get :index, :params => { :set_filter => '0' }
    expect(response).to be_successful
  end

  context 'diff' do
    render_views

    let(:detail) { JournalDetail.create(journal: journal, property: 'attr', prop_key: 'description', old_value: 'oldtext', value: 'text') }

    it 'issue' do
      issue = project.issues.first
      issue.journals << journal
      get :diff, params: { id: journal.id, detail_id: detail.id }
      expect(response).to be_successful
    end

    it 'project' do
      project.journals << journal
      get :diff, params: { id: journal.id, detail_id: detail.id }
      expect(response).to be_successful
    end
  end
end
