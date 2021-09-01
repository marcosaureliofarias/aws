require 'easy_extensions/spec_helper'

describe EasyKnowledgeStoriesController do

  let(:easy_knowledge_story) { FactoryGirl.create(:easy_knowledge_story) }

  render_views

  context 'admin', logged: :admin do

    it 'gets show' do
      get :show, :params => {id: easy_knowledge_story.id}
      assert_response :success
    end

    it 'create' do
      expect{
        post :create, :params => {easy_knowledge_story: {name: 'Update good', description: 'Ema mele mamu'}, format: :json}
      }.to change(EasyKnowledgeStory, :count).by(1)
      expect(response).to be_successful
    end

    it 'update' do
      put :update, :params => {id: easy_knowledge_story.id, easy_knowledge_story: {name: 'Update good', description: 'Ema mele mamu'}, format: :json}
      easy_knowledge_story.reload
      expect(response).to be_successful
      expect(easy_knowledge_story.name).to eq('Update good')
      expect(easy_knowledge_story.description).to eq('Ema mele mamu')
    end

    it 'destroy' do
      delete :destroy, :params => {id: easy_knowledge_story.id, format: :json}
      expect(response).to be_successful
    end

    it 'restore' do
      version = easy_knowledge_story.versions.first
      easy_knowledge_story.description = 'new version'
      expect {
        easy_knowledge_story.save
      }.to change(EasyKnowledgeStoryVersion, :count).by(1)
      expect(easy_knowledge_story.version).to eq(2)
      expect(easy_knowledge_story.description).to eq('new version')
      post :restore, params: {id: easy_knowledge_story.id, version_id: version.id.to_s}
      easy_knowledge_story.reload
      expect(easy_knowledge_story.version).to eq(1)
      expect(easy_knowledge_story.description).not_to eq('new version')
      post :restore, params: {id: easy_knowledge_story.id, version: 2}
      easy_knowledge_story.reload
      expect(easy_knowledge_story.description).to eq('new version')
    end

    it 'restore without a version' do
      post :restore, params: {id: easy_knowledge_story.id}
      expect(response).to have_http_status(404)
    end

    it 'add_comment' do
      post :add_comment, :params => {id: easy_knowledge_story.id, notes: 'Add comment ok', format: :json}
      easy_knowledge_story.reload
      expect(response).to be_successful
      expect(easy_knowledge_story.journals.count).to eq(1)
      expect(easy_knowledge_story.journals.first.notes).to eq('Add comment ok')
    end

    it 'add_toggle_favorite' do
      post :toggle_favorite, :params => {id: easy_knowledge_story.id, format: :json}
      easy_knowledge_story.reload
      expect(response).to be_successful
      expect(easy_knowledge_story.is_favorite?).to be true
    end

    it 'mark_as_read' do
      post :mark_as_read, :params => {id: easy_knowledge_story.id, format: :json}
      easy_knowledge_story.reload
      expect(response).to be_successful
      EasyJob.wait_for_all
      expect(easy_knowledge_story.storyviews).to eq(1)
      expect(easy_knowledge_story.unread?(User.current)).to be false
    end
  end

  context 'regular user', logged: true do
    before(:each) do
      Role.non_member.add_permission! :view_easy_knowledge
      Role.non_member.add_permission! :read_global_stories
    end

    it 'gets index' do
      get :index
      assert_response :success
    end

    it 'gets show' do
      get :show, :params => {:id => easy_knowledge_story.id}
      assert_response :success
    end
  end

end
