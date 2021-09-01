require 'easy_extensions/spec_helper'

describe 'activity fetcher', :logged => :admin do
  let(:project) { FactoryGirl.create(:project) }

  it 'fetch all' do
    EasyActivity.last_events(User.current, nil, 'all')
  end

  it 'fetch selected projects' do
    EasyActivity.last_events(User.current, nil, 'selected_projects', :selected_projects => [project.id])
  end
end
