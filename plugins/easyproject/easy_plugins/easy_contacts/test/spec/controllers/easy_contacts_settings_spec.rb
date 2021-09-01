require 'easy_extensions/spec_helper'

describe EasyContactsSettingsController, logged: :admin do

  render_views

  it 'index fields settings' do
    get :index, params: {tab: 'EasyContactFieldsSettings'}
    expect(response).to render_template('easy_contacts_settings/index')
    expect(response).to be_successful
  end

  context 'fields settings' do


    it 'edit setting' do
      get :edit_field, params: {field_id: 'author_id'}
      expect(response).to render_template('easy_contacts_settings/edit_field')
      expect(response).to be_successful
    end

    it 'edit setting wrong field name' do
      get :edit_field, params: {field_id: 'wrong_field'}
      expect(response).to have_http_status(404)
    end

    it 'update setting 404' do
      post :update_field, params: {field_id: 'author_id_id'}
      expect(response).to have_http_status(404)
    end
  end

end