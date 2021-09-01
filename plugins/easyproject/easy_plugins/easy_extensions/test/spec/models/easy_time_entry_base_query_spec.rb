require 'easy_extensions/spec_helper'

describe EasyTimeEntryBaseQuery, type: :model do

  let(:easy_time_entry_query) { FactoryGirl.build(:easy_time_entry_query) }
  let(:custom_field) { FactoryGirl.create(:issue_custom_field, is_for_all: false) }

  context '#available_columns' do
    it 'when is not for all' do
      custom_field
      expect(easy_time_entry_query.available_columns.detect { |x| x.name.to_s == "cf_#{custom_field.id}" }).to be
    end
  end

  describe 'filters', logged: :admin do
    context ':issue_parent_id' do
      let(:project) { FactoryBot.create(:project, enabled_module_names: ['time_tracking']) }
      let(:parent_issue) { FactoryBot.create(:issue, project: project) }
      let(:issue) { FactoryBot.create(:issue, parent: parent_issue, project: project) }
      let!(:time_entry_on_subtask) { FactoryBot.create(:time_entry, hours: 5, issue: issue, project: project, user: User.current) }
      let!(:time_entry_on_parent_issue) { FactoryBot.create(:time_entry, hours: 1, issue: parent_issue, project: project, user: User.current) }
      let!(:time_entry_without_issue) { FactoryBot.create(:time_entry, hours: 1, issue: nil, project: project, user: User.current) }

      it 'issue_parent_id' do
        query = EasyTimeEntryBaseQuery.new

        query.add_filter("issue_parent_id", '=', [parent_issue.id.to_s])
        expect(query.entities.to_a).to match_array([time_entry_on_parent_issue, time_entry_on_subtask])

        query.add_filter("issue_parent_id", '!', [parent_issue.id.to_s])
        expect(query.entities.to_a).to match_array([time_entry_without_issue])

        query.add_filter("issue_parent_id", '!*', [])
        expect(query.entities.to_a).to match_array([time_entry_on_parent_issue, time_entry_without_issue])

        query.add_filter("issue_parent_id", '*', [])
        expect(query.entities.to_a).to eq([time_entry_on_subtask])
      end
    end
  end
end
