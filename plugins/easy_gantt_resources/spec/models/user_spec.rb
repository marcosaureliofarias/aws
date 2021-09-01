require 'easy_extensions/spec_helper'

RSpec.describe EasyGanttResource, type: :model, logged: :admin do

  # 4.1.2016 is monday
  # 10.1.2016 is sunday

  let(:user) { FactoryGirl.create(:user) }

  around(:each) do |example|
    with_easy_settings(
      easy_gantt_resources_advance_hours_definition: false,
      easy_gantt_resources_hours_per_day: 8,
      easy_gantt_resources_default_allocator:'from_end'
    ) { example.run }
  end

  def create_issue(start_date, due_date)
    FactoryGirl.create(:issue, assigned_to: user, estimated_hours: 10, start_date: start_date, due_date: due_date)
  end

  it 'between_dates' do
   issue1 = create_issue Date.new(2016, 1, 4), Date.new(2016, 1, 5)
   issue2 = create_issue Date.new(2016, 1, 5), Date.new(2016, 1, 6)
   issue1 = create_issue Date.new(2016, 1, 6), Date.new(2016, 1, 7)

   sums = User.easy_resources_sums([user], Date.new(2016, 1, 4), Date.new(2016, 1, 7))
   sums = sums[user.id]

   expect( sums[Date.new(2016, 1, 4)].to_i ).to eq(2)
   expect( sums[Date.new(2016, 1, 5)].to_i ).to eq(10)
   expect( sums[Date.new(2016, 1, 6)].to_i ).to eq(10)
   expect( sums[Date.new(2016, 1, 7)].to_i ).to eq(8)
  end

  context 'easy gantt resources attributes' do
  
    context 'estimated ratio' do
      it 'nil' do
        with_easy_settings(easy_gantt_resources_users_estimated_ratios: nil) {
          expect(user.easy_gantt_resources_estimated_ratio).to be_nil
        }
      end

      it 'get value from the easy setting' do
        with_easy_settings(easy_gantt_resources_users_estimated_ratios: { user.id.to_s => '1.0' }) {
          expect(user.easy_gantt_resources_estimated_ratio).to eq('1.0')
        }
      end

      it 'changed' do
        with_easy_settings(easy_gantt_resources_users_estimated_ratios: { user.id.to_s => '1.0' }) {
          user.easy_gantt_resources_estimated_ratio = '1.2'
          expect(user.easy_gantt_resources_estimated_ratio_changed?).to be_truthy
        }
      end

      it 'put value into the easy setting' do
        with_easy_settings(easy_gantt_resources_users_estimated_ratios: { user.id.to_s => '1.0' }) {
          user.easy_gantt_resources_estimated_ratio = '1.2'
          user.save
          expect(EasySetting.value(:easy_gantt_resources_users_estimated_ratios)[user.id.to_s]).to eq('1.2')
        }
      end
    end

    context 'hours limit' do
      it 'nil' do
        with_easy_settings(easy_gantt_resources_users_hours_limits: nil) {
          expect(user.easy_gantt_resources_hours_limit).to be_nil
        }
      end

      it 'get value from the easy setting' do
        with_easy_settings(easy_gantt_resources_users_hours_limits: { user.id.to_s => '8.0' }) {
          expect(user.easy_gantt_resources_hours_limit).to eq('8.0')
        }
      end

      it 'changed' do
        with_easy_settings(easy_gantt_resources_users_hours_limits: { user.id.to_s => '8.0' }) {
          user.easy_gantt_resources_hours_limit = '6.0'
          expect(user.easy_gantt_resources_hours_limit_changed?).to be_truthy
        }
      end

      it 'put value into the easy setting' do
        with_easy_settings(easy_gantt_resources_users_hours_limits: { user.id.to_s => '8.0' }) {
          user.easy_gantt_resources_hours_limit = '6.0'
          user.save
          expect(EasySetting.value(:easy_gantt_resources_users_hours_limits)[user.id.to_s]).to eq('6.0')
        }
      end
    end
  
    context 'advance hours limit' do
      it 'nil' do
        with_easy_settings(easy_gantt_resources_users_advance_hours_limits: nil) {
          expect(user.easy_gantt_resources_advance_hours_limits).to be_nil
        }
      end

      it 'get value from the easy setting' do
        with_easy_settings(easy_gantt_resources_users_advance_hours_limits: { user.id.to_s => ["8.0", "8.0", "8.0", "8.0", "8.0", "0.0", "0.0"] }) {
          expect(user.easy_gantt_resources_advance_hours_limits).to eq(["8.0", "8.0", "8.0", "8.0", "8.0", "0.0", "0.0"])
        }
      end

      it 'changed' do
        with_easy_settings(easy_gantt_resources_users_advance_hours_limits: { user.id.to_s => ["8.0", "8.0", "8.0", "8.0", "8.0", "0.0", "0.0"] }) {
          user.easy_gantt_resources_advance_hours_limits = ["6.0", "6.0", "6.0", "6.0", "6.0", "0.0", "0.0"]
          expect(user.easy_gantt_resources_advance_hours_limits_changed?).to be_truthy
        }
      end

      it 'put value into the easy setting' do
        with_easy_settings(easy_gantt_resources_users_advance_hours_limits: { user.id.to_s => ["8.0", "8.0", "8.0", "8.0", "8.0", "0.0", "0.0"] }) {
          user.easy_gantt_resources_advance_hours_limits = ["6.0", "6.0", "6.0", "6.0", "6.0", "0.0", "0.0"]
          user.save
          expect(EasySetting.value(:easy_gantt_resources_users_advance_hours_limits)[user.id.to_s]).to eq(["6.0", "6.0", "6.0", "6.0", "6.0", "0.0", "0.0"])
        }
      end
    end
  
  end

end
