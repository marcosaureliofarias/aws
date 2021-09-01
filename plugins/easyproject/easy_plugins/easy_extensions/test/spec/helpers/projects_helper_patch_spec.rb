require 'easy_extensions/spec_helper'

describe ProjectsHelper do
  context 'time entries' do
    let(:project) { FactoryBot.create(:project) }
    let(:issue) { FactoryBot.create(:issue, project: project) }
    let(:time_entry) { FactoryBot.create(:time_entry, issue: issue) }
    let(:time_entry1) { FactoryBot.create(:time_entry, hours: 5, issue: issue) }

    it 'count number of time entries on project' do
      time_entry
      time_entry1

      expect(project_time_entries(project).count).to eq(2)
    end
  end
end
