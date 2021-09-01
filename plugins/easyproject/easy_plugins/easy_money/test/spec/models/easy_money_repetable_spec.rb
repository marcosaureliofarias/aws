require 'easy_extensions/spec_helper'

describe 'repeat easy_money' do

  shared_examples 'repeat easy_money' do |easy_money_factory|
    context "repeating for #{easy_money_factory}" do
      let(:date_now) { '2020-11-03'.to_datetime }
      let(:repeat_count) { 2 }
      let(:repeat_settings) { { 'endtype_count_x' => repeat_count, 'start_timepoint' => date_now, 'period' => 'monthly', 'monthly_period' => '1', 'monthly_option' => 'xth', 'monthly_day' => '5', 'endtype' => 'count', 'create_now' => 'none' } }
      let(:repeat_easy_money) { FactoryBot.build(easy_money_factory, easy_is_repeating: true, easy_repeat_settings: repeat_settings) }
      let(:rake_task) { EasyRakeTaskRepeatingEntities.new(active: true, settings: {}, period: :daily, interval: 1, next_run_at: Time.now) }

      it 'should create next revenue with correct spent_on date' do
        with_time_travel(0.day, now: date_now) do # 2020-11-03
          repeat_easy_money.save

          repeat_count.times do |i|
            with_time_travel(2.day + i.month, now: date_now) do
              expect { rake_task.execute }.to change(repeat_easy_money.class, :count).by(1)
              expect(repeat_easy_money.class.last.spent_on).to eq Date.today
            end
          end
          with_time_travel(2.day + repeat_count.month) do # out of endtype_count_x
            expect { rake_task.execute }.to change(repeat_easy_money.class, :count).by(0)
          end
        end
      end

      it 'should create now with correct spent_on date' do
        with_time_travel(0.day, now: date_now) do # 2020-11-03
          repeat_easy_money.easy_repeat_settings['create_now'] = 'all'
          expect { repeat_easy_money.save }.to change(repeat_easy_money.class, :count).by(1 + repeat_count)
          expect(repeat_easy_money.class.where.not(id: repeat_easy_money.id).pluck(:spent_on)).to match_array (0..repeat_count - 1).map { |e| date_now + 2.day + e.month }
        end
      end

      it 'should create with correct spent_on date when rake task skip creation date' do
        with_time_travel(0.day, now: date_now) do # 2020-11-03
          repeat_easy_money.save
          with_time_travel(12.day, now: date_now) do # 2020-11-15
            expect { rake_task.execute }.to change(repeat_easy_money.class, :count).by(1)
            expect(repeat_easy_money.class.last.spent_on).to eq '2020-11-05'.to_date
          end
        end
      end
    end
  end

  it_behaves_like 'repeat easy_money', :easy_money_expected_revenue
  it_behaves_like 'repeat easy_money', :easy_money_expected_expense
  it_behaves_like 'repeat easy_money', :easy_money_other_revenue
  it_behaves_like 'repeat easy_money', :easy_money_other_expense

end
