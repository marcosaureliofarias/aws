require 'easy_extensions/spec_helper'

describe 'easy time entry base query', :logged => :admin do

  let(:issue1) { FactoryGirl.create(:issue, :estimated_hours => 6)}
  let(:issue2) { FactoryGirl.create(:issue, :estimated_hours => 6)}
  let(:time_entry1) { FactoryGirl.create(:time_entry, :hours => 5, :issue => issue1) }
  let(:time_entry2) { FactoryGirl.create(:time_entry, :hours => 5, :issue => issue2) }
  let(:time_entries) { [time_entry1, time_entry2] }
  let(:easy_time_entry_query) { FactoryGirl.build(:easy_time_entry_query) }

  it 'summarize entities with multiple groups' do
    with_easy_settings(:show_billable_things => true) do
      time_entries
      easy_time_entry_query.column_names = [:hours, :estimated_hours]
      easy_time_entry_query.group_by = ['project', 'easy_is_billable']
      groups = easy_time_entry_query.groups
      expect(groups.keys.count).to eq(2)

      expect(groups.values.map{|x| x[:sums][:bottom].values}).to eq([[5.0, 6.0], [5.0, 6.0]])

      sums = easy_time_entry_query.entity_sum_by_group('hours')
      expect(sums.values).to eq([5.0, 5.0])

      sums_estimated = easy_time_entry_query.entity_sum_by_group('estimated_hours')
      expect(sums_estimated.values).to eq([6.0, 6.0])
    end
  end
end
