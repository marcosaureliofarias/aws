require 'easy_extensions/spec_helper'

RSpec.describe EasyUtils::DateUtils do

  # it 'all dates in year with all shifts' do
  #   setting = with_easy_settings(fiscal_month: 0)
  #   12.times do |fiscal_beginning_month|
  #     fiscal_beginning_month += 1
  #     setting.update_attribute('value', fiscal_beginning_month.to_s)
  #     (EasySetting.beginning_of_fiscal_year..EasySetting.end_of_fiscal_year).each do |date|
  #       fiscal_quarter = EasyUtils::DateUtils.calculate_fiscal_quarter(date)
  #       expect(fiscal_quarter.present?).to be_truthy
  #     end
  #
  #     today = Date.today
  #     [1, 4, 7, 10].each do |quarter_beginning_month|
  #       date = today.change(day: 1, month: quarter_beginning_month)
  #       fiscal_quarter = EasyUtils::DateUtils.calculate_fiscal_quarter(date)
  #       case fiscal_beginning_month
  #         when 1, 4, 7, 10
  #
  #           expect(fiscal_quarter[:from]).to eq(date.beginning_of_month)
  #           expect(fiscal_quarter[:to]).to eq(date.advance(months: 2).end_of_month)
  #         when 2, 5, 8, 11
  #           date = date.advance(months: -2)
  #           expect(fiscal_quarter[:from]).to eq(date.beginning_of_month)
  #           expect(fiscal_quarter[:to]).to eq(date.advance(months: 2).end_of_month)
  #         when 3, 6, 9, 12
  #           date = date.advance(months: -1)
  #           expect(fiscal_quarter[:from]).to eq(date.beginning_of_month)
  #           expect(fiscal_quarter[:to]).to eq(date.advance(months: 2).end_of_month)
  #       end
  #     end
  #   end
  # end

  let (:quarters) do
    {
        Date.new(2016, 1, 1)   => [{ from: Date.new(2016, 1, 1), to: Date.new(2016, 3, 31) },
                                   { from: Date.new(2015, 11, 1), to: Date.new(2016, 1, 31) },
                                   { from: Date.new(2015, 12, 1), to: Date.new(2016, 2, 29) }],
        Date.new(2016, 2, 29)  => [{ from: Date.new(2016, 1, 1), to: Date.new(2016, 3, 31) },
                                   { from: Date.new(2016, 2, 1), to: Date.new(2016, 4, 30) },
                                   { from: Date.new(2015, 12, 1), to: Date.new(2016, 2, 29) }],
        Date.new(2016, 4, 12)  => [{ from: Date.new(2016, 4, 1), to: Date.new(2016, 6, 30) },
                                   { from: Date.new(2016, 2, 1), to: Date.new(2016, 4, 30) },
                                   { from: Date.new(2016, 3, 1), to: Date.new(2016, 5, 31) }],
        Date.new(2016, 8, 12)  => [{ from: Date.new(2016, 7, 1), to: Date.new(2016, 9, 30) },
                                   { from: Date.new(2016, 8, 1), to: Date.new(2016, 10, 31) },
                                   { from: Date.new(2016, 6, 1), to: Date.new(2016, 8, 31) }],
        Date.new(2016, 12, 31) => [{ from: Date.new(2016, 10, 1), to: Date.new(2016, 12, 31) },
                                   { from: Date.new(2016, 11, 1), to: Date.new(2017, 1, 31) },
                                   { from: Date.new(2016, 12, 1), to: Date.new(2017, 2, 28) }]
    }
  end
  it 'fiscal test' do
    12.times do |shift|
      shift = shift + 1
      with_easy_settings(fiscal_month: shift.to_s) do
        (EasySetting.beginning_of_fiscal_year..EasySetting.end_of_fiscal_year).each do |date|
          calculated_range = EasyUtils::DateUtils.calculate_fiscal_quarter(date)
          expect(calculated_range.present?).to be_truthy
        end
        quarters.each do |date, quarter_ranges|
          calculated_range = EasyUtils::DateUtils.calculate_fiscal_quarter(date)
          expect(calculated_range).to eq(quarter_ranges[(shift - 1) % 3])
        end
      end
    end
  end

  it 'fiscal setting nil' do
    with_easy_settings(fiscal_month: nil) do
      (EasySetting.beginning_of_fiscal_year..EasySetting.end_of_fiscal_year).each do |date|
        calculated_range = EasyUtils::DateUtils.calculate_fiscal_quarter(date)
        expect(calculated_range).to eq(from: date.beginning_of_quarter, to: date.end_of_quarter)
      end
      quarters.each do |date, quarter_ranges|
        calculated_range = EasyUtils::DateUtils.calculate_fiscal_quarter(date)
        expect(calculated_range).to eq(quarter_ranges[0])
      end
    end
  end

  describe '.calculate_from_period_options' do
    context 'period days_in_month' do
      it do
        time = EasyUtils::DateUtils.calculate_from_period_options(Date.new(2017, 10, 22), { 'period' => 'days_in_month', 'days_in_month' => [23], 'hours' => '7:00', 'time' => 'defined' })
        expect(time).to eq(Time.new(2017, 10, 23, 7))
      end

      it 'over year' do
        time = EasyUtils::DateUtils.calculate_from_period_options(Date.new(2017, 12, 22), { 'period' => 'days_in_month', 'days_in_month' => [21], 'hours' => '7:00', 'time' => 'defined' })
        expect(time).to eq(Time.new(2018, 1, 21, 7))
      end

      it '31.' do
        time = EasyUtils::DateUtils.calculate_from_period_options(Date.new(2017, 8, 31), { 'period' => 'days_in_month', 'days_in_month' => [31], 'time' => 'cron' })
        expect(time).to eq(Time.new(2017, 9, 30))
      end
    end
  end

end
