require 'easy_extensions/spec_helper'

RSpec.describe EasyExtensions::EasyQueryHelpers::EasyQueryPresenter do
  let(:query) { EasyIssueQuery.new(**period_settings) }
  let(:presenter) { described_class.new(query) }

  describe '#shifted_period_dates' do
    context 'current period leap March to February' do
      let(:period_settings) { { period_start_date: Date.new(2019, 3, 1), period_end_date: Date.new(2020, 2, 29) } }
      it 'returns correct previous period' do
        expect(presenter.shifted_period_dates(-1)).to eq({ period_start_date: Date.new(2018, 3, 1), period_end_date: Date.new(2019, 2, 28) })
      end

      it 'returns correct next period' do
        expect(presenter.shifted_period_dates(1)).to eq({ period_start_date: Date.new(2020, 3, 1), period_end_date: Date.new(2021, 2, 28) })
      end
    end

    context 'current period leap February to January' do
      let(:period_settings) { { period_start_date: Date.new(2020, 2, 1), period_end_date: Date.new(2021, 1, 31) } }
      it 'returns correct previous period' do
        expect(presenter.shifted_period_dates(-1)).to eq({ period_start_date: Date.new(2019, 2, 1), period_end_date: Date.new(2020, 1, 31) })
      end

      it 'returns correct next period' do
        expect(presenter.shifted_period_dates(1)).to eq({ period_start_date: Date.new(2021, 2, 1), period_end_date: Date.new(2022, 1, 31) })
      end
    end

    context 'previous period leap March to February' do
      let(:period_settings) { { period_start_date: Date.new(2020, 3, 1), period_end_date: Date.new(2021, 2, 28) } }
      it 'returns correct previous period' do
        expect(presenter.shifted_period_dates(-1)).to eq({ period_start_date: Date.new(2019, 3, 1), period_end_date: Date.new(2020, 2, 29) })
      end

      it 'returns correct next period' do
        expect(presenter.shifted_period_dates(1)).to eq({ period_start_date: Date.new(2021, 3, 1), period_end_date: Date.new(2022, 2, 28) })
      end
    end

    context 'previous period leap February to January' do
      let(:period_settings) { { period_start_date: Date.new(2021, 2, 1), period_end_date: Date.new(2022, 1, 31) } }
      it 'returns correct previous period' do
        expect(presenter.shifted_period_dates(-1)).to eq({ period_start_date: Date.new(2020, 2, 1), period_end_date: Date.new(2021, 1, 31) })
      end

      it 'returns correct next period' do
        expect(presenter.shifted_period_dates(1)).to eq({ period_start_date: Date.new(2022, 2, 1), period_end_date: Date.new(2023, 1, 31) })
      end
    end

    context 'next period leap March to February' do
      let(:period_settings) { { period_start_date: Date.new(2018, 3, 1), period_end_date: Date.new(2019, 2, 28) } }
      it 'returns correct previous period' do
        expect(presenter.shifted_period_dates(-1)).to eq({ period_start_date: Date.new(2017, 3, 1), period_end_date: Date.new(2018, 2, 28) })
      end

      it 'returns correct next period' do
        expect(presenter.shifted_period_dates(1)).to eq({ period_start_date: Date.new(2019, 3, 1), period_end_date: Date.new(2020, 2, 29) })
      end
    end

    context 'next period leap February to January' do
      let(:period_settings) { { period_start_date: Date.new(2019, 2, 1), period_end_date: Date.new(2020, 1, 31) } }
      it 'returns correct previous period' do
        expect(presenter.shifted_period_dates(-1)).to eq({ period_start_date: Date.new(2018, 2, 1), period_end_date: Date.new(2019, 1, 31) })
      end

      it 'returns correct next period' do
        expect(presenter.shifted_period_dates(1)).to eq({ period_start_date: Date.new(2020, 2, 1), period_end_date: Date.new(2021, 1, 31) })
      end
    end

    context 'previous period starts in leap year but is not leap March to February' do
      let(:period_settings) { { period_start_date: Date.new(2021, 3, 1), period_end_date: Date.new(2022, 2, 28) } }
      it 'returns correct previous period' do
        expect(presenter.shifted_period_dates(-1)).to eq({ period_start_date: Date.new(2020, 3, 1), period_end_date: Date.new(2021, 2, 28) })
      end
    end

    context 'next period ends in leap year but is not leap February to January' do
      let(:period_settings) { { period_start_date: Date.new(2018, 2, 1), period_end_date: Date.new(2019, 1, 31) } }
      it 'returns correct previous period' do
        expect(presenter.shifted_period_dates(1)).to eq({ period_start_date: Date.new(2019, 2, 1), period_end_date: Date.new(2020, 1, 31) })
      end
    end
  end

end
