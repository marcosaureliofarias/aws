require 'easy_extensions/spec_helper'

describe EasyMoneyController, type: :request do
  include_context 'logged as'

  let(:project) { FactoryBot.create(:project) }
  let(:issue) { FactoryBot.create(:issue, project: project, subject: 'Test subject') }

  describe 'render_entity_select' do

    it 'with entity_id' do
      post '/easy_money/render_entity_select', params: { project_id: project.id, entity_type: 'Issue', entity_id: issue.id }, xhr: true
      expect(response).to have_http_status(:success)
      expect(body).to include('<input type=\"text\" id=\"easy_money_issue_autocomplete_autocomplete\" value=\"Test subject\" />')
    end

    it 'without entity_id' do
      post '/easy_money/render_entity_select', params: { project_id: project.id, entity_type: 'Issue' }, xhr: true
      expect(response).to have_http_status(:success)
      expect(body).to include('<input type=\"text\" id=\"easy_money_issue_autocomplete_autocomplete\" value=\"\" />')
    end

  end

end