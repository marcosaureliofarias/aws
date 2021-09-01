require 'easy_extensions/spec_helper'

describe EasyKnowledgeProjectsController do

  let(:project) { FactoryGirl.create(:project, :enabled_module_names => ['easy_knowledge']) }

  render_views

  context 'admin', logged: :admin do
    it 'gets index' do
      get :index, :params => {:project_id => project.id}
      assert_response :success
    end
  end

  context 'regular user', logged: true do
    before(:each) do
      Role.non_member.add_permission! :manage_project_categories
      Role.non_member.add_permission! :view_easy_knowledge
    end

    it 'gets index' do
      get :index, :params => {:project_id => project.id}
      assert_response :success
    end
  end

end
