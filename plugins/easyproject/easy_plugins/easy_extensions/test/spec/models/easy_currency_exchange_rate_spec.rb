require 'easy_extensions/spec_helper'

describe EasyCurrencyExchangeRate do

  describe 'existing data' do
    let!(:exchange_rate_with_valid_on) { FactoryBot.create(:easy_currency_exchange_rate, valid_on: '2018-11-01', rate: 25) }
    let!(:exchange_rate_with_valid_on1) { FactoryBot.create(:easy_currency_exchange_rate, valid_on: '2018-11-02', rate: 26) }
    let!(:exchange_rate_without_valid_on) { FactoryBot.create(:easy_currency_exchange_rate, valid_on: nil, rate: 30) }

    context 'with valid on' do
      it '#find_exchange_rate_value' do
        expect(described_class.find_exchange_rate_value('CZK', 'EUR', '2018-11-01'.to_date)).to eq(25)
      end
    end

    context 'without valid on' do
      it '#find_exchange_rate_value' do
        expect(described_class.find_exchange_rate_value('CZK', 'EUR', '2018-10-31'.to_date)).to eq(30)
      end
    end
  end

  context 'with same currency' do
    it '#find_exchange_rate_value' do
      expect(described_class.find_exchange_rate_value('CZK', 'CZK', '2018-11-01'.to_date)).to eq(1)
    end
  end

end
