require 'easy_extensions/spec_helper'

describe WikiController, logged: :admin do
  render_views

  let(:project) { FactoryBot.create(:project, add_modules: ['wiki']) }

  context 'show' do
    it 'png' do
      get :show, params: {project_id: project.id, id: 'sd-show-user-profile', format: 'png'}
      expect(response).to have_http_status(406)
    end

    it 'html' do
      get :show, params: {project_id: project.id, id: 'sd-show-user-profile'}
      expect(response).to be_successful
    end
  end

  context 'edit' do
    it 'png' do
      get :edit, params: {project_id: project.id, id: 'sd-show-user-profile', format: 'png'}
      expect(response).to have_http_status(406)
    end

    it 'html' do
      get :edit, params: {project_id: project.id, id: 'sd-show-user-profile'}
      expect(response).to be_successful
    end
  end

end
