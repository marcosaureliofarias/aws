require 'easy_extensions/spec_helper'
describe 'routes for EasyTimeEntry/timelog', type: :routing do

  shared_examples 'time_entry routes' do |method, action, id, action_way|
    it "#{action}" do
      url = ['time_entries', id, action_way].compact.join('/')
      expectation_routes = { controller: 'easy_time_entries', action: action }
      expectation_routes.merge!(id: id) if id
      expect(method => url).to route_to(expectation_routes)
    end
  end

  it_behaves_like 'time_entry routes', 'get', 'index'
  it_behaves_like 'time_entry routes', 'get', 'show', '1'
  it_behaves_like 'time_entry routes', 'get', 'new', nil, 'new'
  it_behaves_like 'time_entry routes', 'get', 'edit', '1', 'edit'
  it_behaves_like 'time_entry routes', 'post', 'create'
  it_behaves_like 'time_entry routes', 'patch', 'update', '1'
  it_behaves_like 'time_entry routes', 'put', 'update', '1'
  it_behaves_like 'time_entry routes', 'delete', 'destroy', '1'
  it_behaves_like 'time_entry routes', 'get', 'user_spent_time', nil, 'user_spent_time'
  it_behaves_like 'time_entry routes', 'post', 'user_spent_time', nil, 'user_spent_time'
  it_behaves_like 'time_entry routes', 'get', 'change_role_activities', nil, 'change_role_activities'
  it_behaves_like 'time_entry routes', 'post', 'change_role_activities', nil, 'change_role_activities'
  it_behaves_like 'time_entry routes', 'get', 'change_projects_for_bulk_edit', nil, 'change_projects_for_bulk_edit'
  it_behaves_like 'time_entry routes', 'post', 'change_projects_for_bulk_edit', nil, 'change_projects_for_bulk_edit'
  it_behaves_like 'time_entry routes', 'get', 'change_issues_for_bulk_edit', nil, 'change_issues_for_bulk_edit'
  it_behaves_like 'time_entry routes', 'post', 'change_issues_for_bulk_edit', nil, 'change_issues_for_bulk_edit'
  it_behaves_like 'time_entry routes', 'get', 'change_issues_for_timelog', nil, 'change_issues_for_timelog'
  it_behaves_like 'time_entry routes', 'post', 'change_issues_for_timelog', nil, 'change_issues_for_timelog'
  it_behaves_like 'time_entry routes', 'get', 'bulk_edit', nil, 'bulk_edit'
  it_behaves_like 'time_entry routes', 'post', 'bulk_edit', nil, 'bulk_edit'
  it_behaves_like 'time_entry routes', 'post', 'bulk_update', nil, 'bulk_update'
  it_behaves_like 'time_entry routes', 'delete', 'destroy', nil, 'destroy'

  it 'post time_entries/resolve_easy_lock' do
    expect(post('time_entries/resolve_easy_lock/true')).to route_to(controller: 'easy_time_entries', action: 'resolve_easy_lock', locked: 'true')
  end

  it 'GET projects/:project_id/time_entries' do
    expect(get('projects/1/time_entries')).to route_to(controller: 'easy_time_entries', action: 'index', project_id: '1')
  end

  it 'GET projects/:project_id/time_entries/report' do
    expect(get('projects/1/time_entries/report')).to route_to(controller: 'easy_time_entries', action: 'report', project_id: '1')
  end
end
