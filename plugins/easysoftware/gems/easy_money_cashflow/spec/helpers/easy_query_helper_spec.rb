
RSpec.describe EasyQueryHelper do
  describe '#query_period_name' do
    let(:query_period_settings) { EasyExtensions::EasyQueryHelpers::PeriodSetting.new(
                            { period_date_period: "current_fiscal_year",
                                    period_date_period_type: "1",
                                    period_zoom: "quarter"
                                  })
                                }
    let(:cash_flow_query) { FactoryBot.build(:easy_money_cash_flow_query,
                                             period_settings: query_period_settings) }

    it 'fiscal year start at January' do
      with_easy_settings('fiscal_month' => '1') do
       query_period_settings[:period_start_date] = Date.new(2019, 01, 01)
       query_period_settings[:period_end_date] = Date.new(2019, 12, 31)
       expect(helper.query_period_name(cash_flow_query, 0)).to eq(I18n.t('date.quarter_names')[0])
      end
    end

    it 'fiscal year start at April' do
      with_easy_settings('fiscal_month' => '4') do
        query_period_settings[:period_start_date] = Date.new(2019, 04, 01)
        query_period_settings[:period_end_date] = Date.new(2020, 03, 31)
        expect(helper.query_period_name(cash_flow_query, 0)).to eq(I18n.t('date.quarter_names')[0])
      end
    end
  end
end
