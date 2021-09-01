require 'easy_extensions/spec_helper'

describe EasyKnowledgeUsersController do

  render_views

  context 'admin', logged: :admin do
    it 'gets index' do
      get :index
      assert_response :success
    end
  end

  context 'regular user', logged: true do
    before(:each) do
      Role.non_member.add_permission! :manage_own_personal_categories
      Role.non_member.add_permission! :view_easy_knowledge
    end

    it 'gets index' do
      get :index
      assert_response :success
    end
  end

end
