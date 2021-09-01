require 'easy_extensions/spec_helper'

describe EasyTimeEntriesController, type: :request do
  include_context 'easy time entries'

  context 'logged as admin' do
    include_context 'logged as admin'

    it '#new' do
      get new_easy_time_entry_path
      expect(response).to have_http_status(:success)
      expect(response).to render_template('bulk_time_entries/index')
    end

    describe 'remote new' do
      it 'modal without existing project' do
        get new_easy_time_entry_path, params: { modal: true }, xhr: true
        expect(response).to have_http_status(:success)
        expect(response).to render_template('easy_time_entries/no_projects')
      end

      it 'modal with existing project' do
        project
        get new_easy_time_entry_path, params: { modal: true }, xhr: true
        expect(response).to have_http_status(:success)
        expect(response).to render_template('new_modal')
      end
    end

    it '#create' do
      expect { post easy_time_entries_path, params: { project_id: project.id, issue_id: issue.id, time_entry: { activity_id: time_entry_activity.id, hours: 1.5, easy_time_entry_range: { from: '10.00', to: '11:30' } } } }.to change(TimeEntry, :count).by(1)
    end

    describe '#update' do
      it 'changes attributes' do
        put easy_time_entry_path(id: time_entry.id, spent_on: '2018-04-04', time_entry: { hours: 2 })
        t = time_entry.reload
        expect(t.spent_on).to eq('2018-04-04'.to_date)
        expect(t.hours).to eq(2)
      end

      context 'removing issue' do
        it 'sets issue_id to nil' do
          put easy_time_entry_path(id: time_entry.id, issue_id: '')
          expect(time_entry.reload.issue_id).to be_nil
        end
      end
    end

    it '#show' do
      get easy_time_entry_path(time_entry.id)
      expect(response).to have_http_status(:success)
    end

    # it '#user_spent_time' do
    #   get user_spent_time_easy_time_entries_path(spent_on: time_entry.spent_on)
    #   expect(response).to have_http_status(:success)
    #   expect(response).to render_template(partial: 'easy_time_entries/user_spent_time')
    # end

    it '#change_role_activities' do
      post change_role_activities_easy_time_entries_path, params: { project_id: project.id, tag_name_prefix: 'time_entry' }, xhr: true
      expect(response).to have_http_status(:success)
      expect(response).to render_template('timelog/change_role_activities')
    end

    it '#change_issues_for_timelog' do
      issue
      post change_issues_for_timelog_easy_time_entries_path, params: { format: :json, term: issue.subject }
      expect(response).to render_template('timelog/change_issues_for_timelog')
    end

  end

  context 'JSON requests' do
    include_context 'logged as admin'

    it 'returns http created and created entity' do
      post easy_time_entries_path, params: time_entry_json_params
      expect(response).to have_http_status(:created)
      hash_body = nil
      expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_exception
      expect(hash_body.keys).to match_array(%w[time_entry])
      time_entry_expected_attributes = %w[id project user comments spent_on easy_range_from easy_range_to entity_id
                                            entity_type created_on updated_on]
      expect(hash_body[:time_entry].keys).to include(*time_entry_expected_attributes)
    end
  end

end
