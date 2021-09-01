require 'easy_extensions/spec_helper'

describe ModalSelectorsController do

  render_views

  context 'admin', logged: :admin do
    it 'easy_contact_for_project' do
      get :index, :params => {:entity_action => 'easy_contact_for_project', :entity_attribute => 'name'}
      assert_response :success
    end

    it 'easy_contact_for_mail' do
      get :index, :params => {:entity_action => 'easy_contact_for_mail', :entity_attribute => 'name'}
      assert_response :success
    end

    it 'easy_contact_group' do
      get :index, :params => {:entity_action => 'easy_contact_group', :entity_attribute => 'name'}
      assert_response :success
    end

    it 'easy_contact' do
      get :index, :params => {:entity_action => 'easy_contact', :entity_attribute => 'name'}
      assert_response :success
    end

  end

end
