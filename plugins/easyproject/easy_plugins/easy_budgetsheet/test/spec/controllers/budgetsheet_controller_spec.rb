require 'easy_extensions/spec_helper'

describe BudgetsheetController do

  let!(:time_entries) { FactoryGirl.create_list(:time_entry, 2) }
  let(:easy_money_rate_type) { FactoryGirl.create(:easy_money_rate_type) }

  describe 'GET /budgetsheet', logged: :admin do
    render_views

    it 'should assign query' do
      get :index
      expect( assigns(:query) ).not_to be_nil
      expect( response ).to be_successful
    end

    it 'should serve csv requests' do
      get :index, :params => {format: 'csv', set_filter: '0', easy_query: {columns_to_export: 'all'}}
      expect( response ).to be_successful
      expect( response.content_type ).to eq( 'text/csv' )
    end

    it 'should serve pdf requests' do
      get :index, :params => {format: 'pdf', set_filter: '0', easy_query: {columns_to_export: 'all'}}
      expect( response ).to be_successful
      expect( response.content_type ).to eq( 'application/pdf' )
    end

    it 'should serve xlsx requests' do
      get :index, :params => {format: 'xlsx', set_filter: '0', easy_query: {columns_to_export: 'all'}}
      expect( response ).to be_successful
      expect( response.content_type ).to eq( 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' )
    end

#    it 'with currencies' do
#      easy_money_rate_type
#      get :index, :params => {:set_filter => '1', :show_sum_row => '1', :column_names => ['hours', 'easy_money_rate_type_internal'], :easy_currency_code => 'EUR'}
#      expect( response ).to be_successful
#    end
  end

end
