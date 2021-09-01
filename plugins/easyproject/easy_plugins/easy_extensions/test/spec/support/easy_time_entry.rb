RSpec.shared_context 'easy time entries' do

  let(:user) { FactoryBot.create(:user) }
  let(:project) { FactoryBot.create(:project) }
  let(:issue) { FactoryBot.create(:issue, project: project) }
  let(:time_entry_activity) { FactoryBot.create(:time_entry_activity, projects: [project]) }

  let(:time_entry) { FactoryBot.create(:time_entry, project: project, user: user, activity: time_entry_activity, issue: issue) }
  let(:time_entries) { FactoryBot.create_list(:time_entry, 3, project: project, issue: issue, activity: time_entry_activity, user: user) }

  let(:time_entry_params) do
    { project_id: project.id,
      spent_on:   Date.today.to_s,
      time_entry: { hours:                 nil,
                    easy_time_entry_range: { from: '10.00', to: '11:30' },
                    activity_id:           time_entry_activity.id,
                    comments:              'Books & Tools' } }
  end

  let(:time_entry_json_params) { time_entry_params.merge(format: :json) }

  let(:time_entry_locked) { FactoryBot.create(:time_entry, project: project, issue: issue, easy_locked: true, user: user, activity: time_entry_activity) }

end