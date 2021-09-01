require 'easy_extensions/spec_helper'

describe EasyPagesController, logged: :admin do
  render_views

  let(:easy_page) { FactoryBot.create(:easy_page) }
  let(:project_easy_page) { FactoryBot.create(:easy_page, page_scope: 'project') }

  context '#update' do
    it 'change name' do
      put :update, params: { id: easy_page.id, easy_page: { user_defined_name: 'abcd' } }
      expect(easy_page.reload.user_defined_name).to eq('abcd')
    end
  end

  context '#edit' do
    it 'custom page' do
      get :edit, params: { id: easy_page.id }
      expect(response).to be_successful
    end

    it 'project page' do
      get :edit, params: { id: project_easy_page.id }
      expect(response).to be_successful
    end
  end

end
