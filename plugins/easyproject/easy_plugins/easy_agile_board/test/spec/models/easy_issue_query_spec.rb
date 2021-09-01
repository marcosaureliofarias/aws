require 'easy_extensions/spec_helper'

describe EasyIssueQuery, logged: :admin do
  it 'doesnt use kanban params for export' do
    query = EasyIssueQuery.new
    query.settings = {"kanban" => {"kanban_group" => "status"}}
    expect(query.path).to include('kanban')
    expect(query.path(export: true)).not_to include('kanban')
  end
end
