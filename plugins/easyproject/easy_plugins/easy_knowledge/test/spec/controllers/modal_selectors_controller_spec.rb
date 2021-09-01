require 'easy_extensions/spec_helper'

describe ModalSelectorsController do

  render_views

  context 'admin', logged: :admin do
    it 'easy_knowledge_project' do
      get :index, :params => {:entity_action => 'easy_knowledge_project', :entity_attribute => 'name'}
      assert_response :success
    end
  end

end
