require_relative '../spec_helper'

RSpec.describe EasyMoneyCashFlowController, logged: :admin do

  let!(:easy_money_expected_expenses) { FactoryBot.create(:easy_money_expected_expense)}

  describe 'GET index' do
    render_views

    it 'renders index' do
      get :index
      expect(response).to be_successful
    end

    it 'exports index to xlsx' do
      get :index, params: { format: 'xlsx', set_filter: '0', easy_query: { columns_to_export: 'all' }}
      expect(response).to be_successful
      expect(response.content_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    end

  end

end if Redmine::Plugin.installed?(:easy_money)
