require 'easy_extensions/spec_helper'

describe UsersController, logged: :admin do

  describe 'user with supervisor' do
    render_views

    let(:user) { FactoryBot.create(:user) }

    it 'api show' do
      EasyOrgChartNode.create_nodes!({'id' => User.current.to_gid_param, 'children' => {'1' => {'id' => user.to_gid_param}}})
      get :show, params: { 'id' => user.id, 'format' => 'json' }
      expect(response).to be_successful
      data = JSON.parse(response.body)
      expect(data['user']['supervisor_user_id']).to eq(User.current.id)
    end
  end

end