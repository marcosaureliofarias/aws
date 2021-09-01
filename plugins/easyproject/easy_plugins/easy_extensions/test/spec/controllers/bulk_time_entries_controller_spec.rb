require 'easy_extensions/spec_helper'

describe BulkTimeEntriesController, logged: :admin do
  let(:project) { FactoryGirl.create(:project) }
  let(:issue) { FactoryGirl.create(:issue, project: project) }
  let(:time_entry_activity) { FactoryGirl.create(:time_entry_activity, project: project, projects: [project]) }

  describe 'POST save -- /bulk_time_entries' do
    let(:time_entry_params) do
      { user_id:    User.current.id,
        project_id: project.id,
        spent_on:   Date.today.to_s,
        time_entry: { hours:                 nil,
                      easy_time_entry_range: { from: '10.00', to: '11:30' },
                      activity_id:           time_entry_activity.id,
                      comments:              'Bla Bla' } }
    end

    it 'create time_entry' do
      expect { post :save, params: time_entry_params }.to change(TimeEntry, :count).by(1)
      time_entry = TimeEntry.last
      expect(time_entry.hours).to eq(1.5)
      expect(time_entry.easy_range_from).not_to be_nil
      expect(time_entry.easy_range_to).not_to be_nil
    end

    context 'JSON requests' do
      let(:time_entry_json_params) { time_entry_params.merge(format: :json) }

      it 'returns http created and renders show template' do
        post :save, params: time_entry_json_params
        expect(response).to have_http_status(:created)
        expect(response).to render_template('timelog/show')
      end

    end
  end
end
