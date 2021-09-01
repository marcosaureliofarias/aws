require 'easy_extensions/spec_helper'

describe EasyMoneyRatesController, logged: :admin do
  describe 'save setting as global, all, self and self_and_descendants' do
    let(:user) { FactoryGirl.create(:user) }
    let(:user1) { FactoryGirl.create(:user) }
    let(:easy_money_rate_type) { FactoryGirl.create(:easy_money_rate_type) }
    let!(:project) { FactoryGirl.create(:project, enabled_module_names: ['easy_money'], members: [user]) }
    let!(:project1) { FactoryGirl.create(:project, parent_id: project.id, enabled_module_names: ['easy_money'], members: [user1]) }
    let!(:project2) { FactoryGirl.create(:project, enabled_module_names: ['easy_money'], members: [user]) }

    it 'works with empty values' do
      params = { entity_type: 'Role', save_setting: 'global_setting', easy_money_rates: {
        'Role' => {
          user.roles.first.id => { easy_money_rate_type.id => '' },
          user.roles.last.id => { easy_money_rate_type.id => '20' }
        }
      } }

      expect{ post :update_rates, params: params }.to change{ EasyMoneyRate.count }.by(1)
    end

    it 'zero rates' do
      params = { entity_type: 'Role', save_setting: 'global_setting', easy_money_rates: {
        'Role' => {
          user.roles.first.id => { easy_money_rate_type.id => '20' },
          user.roles.last.id => { easy_money_rate_type.id => '0' }
        }
      } }

      project_params = { entity_type: 'User', save_setting: 'self_and_descendants', easy_money_rates: {
        'Role' => {
          user.roles.first.id => { easy_money_rate_type.id => '0' },
          user.roles.last.id => { easy_money_rate_type.id => '50' }
        } }, project_id: project.id }

      post :update_rates, params: params
      post :update_rates, params: project_params
      expect(EasyMoneyRate.where(project_id: nil).map(&:unit_rate)).to match_array([20, 0])
      expect(project1.easy_money_rates.map(&:unit_rate)).to match_array([0, 50])
    end

    it 'update rates' do
      post :update_rates, params: { entity_type: 'User', save_setting: 'global_setting', easy_money_rates: { 'Principal' => { user.id => { easy_money_rate_type.id => '3' } } } }

      expect(user.easy_money_rates.where(project_id: nil).first.unit_rate.to_i).to eq(3)
      expect(project.easy_money_rates).to eq([])
      expect(project1.easy_money_rates).to eq([])
      expect(project2.easy_money_rates).to eq([])

      post :update_rates, params: { entity_type: 'User', save_setting: 'self', easy_money_rates: { 'Principal' => { user.id => { easy_money_rate_type.id => '5' } } }, project_id: project.id }

      expect(user.easy_money_rates.where(project_id: nil).first.unit_rate.to_i).to eq(3)
      expect(project.easy_money_rates.where(entity_type: 'Principal', entity_id: user.id).first.unit_rate.to_i).to eq(5)
      expect(project1.easy_money_rates).to eq([])
      expect(project2.easy_money_rates).to eq([])

      post :update_rates, params: { entity_type: 'User', save_setting: 'all_projects', easy_money_rates: { 'Principal' => { user.id => { easy_money_rate_type.id => '30' } } } }

      expect(project.easy_money_rates).to eq([])
      expect(project1.easy_money_rates).to eq([])
      expect(project2.easy_money_rates).to eq([])
      expect(user.easy_money_rates.where(project_id: nil).first.unit_rate.to_i).to eq(30)

      post :update_rates, params: { entity_type: 'User', save_setting: 'self_and_descendants', easy_money_rates: { 'Principal' => { user.id => { easy_money_rate_type.id => '60' }, user1.id => { easy_money_rate_type.id => '50' } } }, project_id: project.id }

      expect(project.easy_money_rates.where(entity_type: 'Principal', entity_id: user.id).first.unit_rate.to_i).to eq(60)
      expect(project1.easy_money_rates.where(entity_type: 'Principal', entity_id: user1.id).first.unit_rate.to_i).to eq(50)
      expect(project2.easy_money_rates).to eq([])
      expect(user.easy_money_rates.where(project_id: nil).first.unit_rate.to_i).to eq(30)
    end

  end
end
