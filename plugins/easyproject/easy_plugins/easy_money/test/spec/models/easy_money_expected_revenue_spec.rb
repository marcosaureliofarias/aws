require 'easy_extensions/spec_helper'

describe EasyMoneyExpectedRevenue do
  let(:easy_money_expected_revenue) { FactoryBot.build_stubbed(:easy_money_expected_revenue) }

  context 'calculate vat' do
    it 'valid' do
      easy_money_expected_revenue.price1 = 10
      easy_money_expected_revenue.price2 = 8
      expect(easy_money_expected_revenue.calculate_vat).to eq(25.0)
    end

    it 'nan' do
      easy_money_expected_revenue.price1 = BigDecimal(0)
      easy_money_expected_revenue.price2 = BigDecimal(0)
      expect(easy_money_expected_revenue.calculate_vat).to eq(0.0)
    end
  end
end
