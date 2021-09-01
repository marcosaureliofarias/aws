require_relative '../spec_helper'

describe 'EasyEntityActivityCrmCaseQuery', logged: :admin, deletion: true do
  let!(:easy_currency_eur) { FactoryBot.create(:easy_currency, :eur) }

  it 'associated price column with currency' do
    begin
      unless ActiveRecord::Migration.column_exists? :easy_crm_cases, :price_EUR
        ActiveRecord::Migration.add_column :easy_crm_cases, :price_EUR, :float
      end
      query = EasyEntityActivityCrmCaseQuery.new
      query.easy_currency_code = 'EUR'
      column = query.get_column('easy_crm_cases.price')
      expect(query.entity_sum(column)).to be_zero
    ensure
      if ActiveRecord::Migration.column_exists? :easy_crm_cases, :price_EUR
        ActiveRecord::Migration.remove_column :easy_crm_cases, :price_EUR, :float
      end
    end
  end

  describe 'sales_activity filters' do
    let!(:phone_call) { FactoryBot.create(:easy_entity_activity_category) }

    it do
      query = EasyEntityActivityCrmCaseQuery.new
      query.add_filter("easy_crm_cases.sales_activity_#{phone_call.id}_not_in", 'date_period_1', { 'period' => 'current_month' })

      expect(query.entities.count).to eq(0)
    end
  end
end
