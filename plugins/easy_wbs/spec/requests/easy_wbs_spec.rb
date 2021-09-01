require_relative '../spec_helper'

describe EasyWbsController, type: :request, logged: :admin do
  context 'easy money', skip: !Redmine::Plugin.installed?(:easy_money) do
    let(:project) { FactoryBot.create(:project, enabled_module_names: ['easy_money', 'easy_wbs']) }
    let(:custom_field) { FactoryBot.create(:custom_field, type: 'EasyMoneyOtherRevenueCustomField') }

    it '#budget_overview' do
      custom_field
      post "/projects/#{project.id}/easy_wbs/budget_overview", params: { entity_type: 'Project', entity_id: project.id, tab: 'other_revenue' }
      expect(response).to be_successful
      expect(response.body).to include("easy_money[custom_field_values][#{custom_field.id}]")
    end
  end
end