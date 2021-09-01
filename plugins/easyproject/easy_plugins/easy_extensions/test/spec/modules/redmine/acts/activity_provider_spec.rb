require 'easy_extensions/spec_helper'

RSpec.describe Redmine::Acts::ActivityProvider do

  describe '.easy_find_events' do

    # class with project_id column
    class DummyIssueProvider < Issue
      acts_as_activity_provider
    end

    # class without project_id column
    class DummyUserProvider < User
      acts_as_activity_provider
    end

    let(:options) { { project_ids: [5] } }

    it 'does not return Scope.none' do
      event_type = DummyIssueProvider.name.underscore.pluralize
      scope      = DummyIssueProvider.easy_find_events(event_type, User.current, nil, nil, options)

      expect(scope.to_sql).not_to eq(DummyIssueProvider.none)
    end

    it 'returns Scope.none' do
      event_type = DummyUserProvider.name.underscore.pluralize
      scope      = DummyUserProvider.easy_find_events(event_type, User.current, nil, nil, options)

      expect(scope).to eq(DummyUserProvider.none)
    end

  end

end
