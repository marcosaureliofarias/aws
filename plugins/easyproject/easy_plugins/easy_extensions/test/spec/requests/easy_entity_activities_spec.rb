require 'easy_extensions/spec_helper'

describe 'EasyEntityActivities', type: :request do
  describe 'GET /easy_entity_activities/:id.:api' do
    include_context 'logged as admin'

    let(:user) { FactoryBot.create(:user) }
    let(:issue) { FactoryBot.create(:issue) }
    let(:category) { EasyEntityActivityCategory.create(name: 'cat') }
    let(:entity_activity) { EasyEntityActivity.create(entity_type: 'Issue', entity_id: issue.id, category_id: category.id, easy_entity_activity_users: [user]) }

    it 'renders XML with user attendees' do
      get easy_entity_activity_path(entity_activity, format: 'xml')
      expect(response.body).to include("<users_attendees type=\"array\"><user><id>#{user.id}</id><name>#{user.name}</name></user></users_attendees>")
    end
  end
end

