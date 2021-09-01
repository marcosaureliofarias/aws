require_relative '../spec_helper'

describe EasyOrgChartController, logged: :admin do

  render_views

  let(:user1) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }

  it 'api tree' do
    EasyOrgChartNode.create_nodes!({'id' => user1.to_gid_param, 'children' => {'1' => {'id' => user2.to_gid_param}}})
    get :tree, params: { format: 'json' }
    expect(response).to be_successful
    data = JSON.parse(response.body)
    expect(data['user_id']).to eq(user1.id)
    expect(data['children'].count).to eq(1)
    expect(data['children'].first['user_id']).to eq(user2.id)
  end

  context 'api create' do
    it 'nodes' do
      expect {
        post :create, params: { format: 'json', easy_org_chart: {id: user1.to_gid_param, children: {'1' => {id: user2.to_gid_param}}} }
      }.to change(EasyOrgChartNode, :count).by(2)
    end
  end

end