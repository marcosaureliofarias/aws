require 'easy_extensions/spec_helper'

describe EasyMoneySettingsController, logged: :admin do
  let(:project) { FactoryBot.create(:project, enabled_module_names: ['easy_money']) }
  let(:rate) { FactoryBot.create(:easy_money_rate) }

  describe 'user rates' do
    before(:each) do
      rate
      allow_any_instance_of(EasyMoneyUserRateQuery).to receive(:required_rate_type).and_return('all')
    end

    after(:each) do
      allow_any_instance_of(EasyMoneyUserRateQuery).to receive(:required_rate_type).and_call_original
    end

    it 'project' do
      get :project_settings, params: { tab: 'EasyMoneyRateUser', project_id: project.id }
      expect( response ).to be_successful
    end

    it 'global' do
      get :index, params: { tab: 'EasyMoneyRateUser' }
      expect( response ).to be_successful
    end
  end

  it 'reorder hierarchy' do
    rate_type = FactoryBot.create(:easy_money_rate_type)
    p1 = FactoryBot.create(:easy_money_rate_priority, entity_type: 'User', rate_type: rate_type)
    p2 = FactoryBot.create(:easy_money_rate_priority, entity_type: 'Role', rate_type: rate_type)
    expect([p1.reload.position, p2.reload.position]).to eq [1, 2]
    post :move_rate_priority, params: {id: p2.id, easy_money_rate_priority: {reorder_to_position: 1}}
    expect([p1.reload.position, p2.reload.position]).to eq [2, 1]
  end
end
