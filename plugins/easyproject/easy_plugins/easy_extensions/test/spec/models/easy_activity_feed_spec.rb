require 'easy_extensions/spec_helper'
describe 'Easy activity feed' do

  let!(:project) {
    project = FactoryGirl.create(:project, number_of_members: 2)
    project.enable_module!('easy_crm')
    project
  }
  let(:user1) { project.users.first }
  let(:user2) { project.users.last }
  let(:user3) { FactoryBot.create(:user) }
  let(:issue) { FactoryGirl.create(:issue, project: project) }
  let(:issue2) { FactoryGirl.create(:issue, project: project) }
  let(:easy_crm_case1) { FactoryGirl.create(:easy_crm_case, project: project) }
  let(:easy_crm_case2) { FactoryGirl.create(:easy_crm_case, project: project) }

  def user_current_events(user, event_type = 'all')
    if event_type == 'all'
      events = EasyActivity.last_events(user, project, event_type)
    else
      events = EasyActivity.last_events(user, project, EasyActivity::SELECTED_ACTIVITY_SCOPE, :selected_event_types => [event_type])
    end

    events
  end

  it 'has correnct event changes' do
    events_count_before = user_current_events(user2).count
    issue
    events             = user_current_events(user2)
    events_count_after = events.count
    expect(events_count_after).to eq events_count_before + 1

    logged_user user2

    events.each do |event|
      if event.respond_to?(:mark_as_read)
        event.mark_as_read
      end
    end
    EasyJob.wait_for_all

    events = user_current_events(user2)
    expect(events.count).to eq 0

    logged_user user1

    issue2

    events = user_current_events(user2)
    expect(events.count).to eq 1
  end

  it 'creates event when easy crm case is updated' do
    event_type          = 'easy_crm_cases'
    events_count_before = user_current_events(user2, event_type).count
    easy_crm_case1
    easy_crm_case2

    events_count_after = user_current_events(user2, event_type).count
    expect(events_count_after).to eq events_count_before + 2

    logged_user user2

    events_count_before = user_current_events(user1, event_type).count

    easy_crm_case1.init_journal(User.current, 'test')
    easy_crm_case1.save

    events_count_after = user_current_events(user1, event_type).count

    expect(events_count_after).to eq events_count_before + 1
  end if Redmine::Plugin.installed?(:easy_crm)

  it 'creates event when issue is updated' do
    event_type          = 'issues'
    events_count_before = user_current_events(user2, event_type).count
    issue
    issue2

    events_count_after = user_current_events(user2, event_type).count
    expect(events_count_after).to eq events_count_before + 2

    logged_user user2

    events_count_before = user_current_events(user1, event_type).count

    issue.init_journal(User.current, 'test')
    issue.save

    events_count_after = user_current_events(user1, event_type).count

    expect(events_count_after).to eq events_count_before + 1
  end

  it 'should have easy_activity_provider_options on Issue' do
    expect(Issue.activity_provider_options[:easy_activity_options]['issues']).not_to eq(nil)
  end

  it 'should be unread only if notes are updated' do
    event_type          = 'issues'
    events_count_before = user_current_events(user2, event_type).count
    issue
    issue.mark_as_read(user2)
    issue.mark_as_read(user3)
    EasyJob.wait_for_all

    issue2

    logged_user user2

    events_count_before = user_current_events(user1, event_type).count

    issue.assigned_to = User.last
    issue.save

    events_count_after = user_current_events(user1, event_type).count

    # update without notes will not create new event
    expect(events_count_after).to eq events_count_before
    expect(issue.unread?(user2)).to eq false

    issue.init_journal(User.current, 'test')
    issue.save

    events_count_after = user_current_events(user1, event_type).count

    # update with notes will create new event
    expect(events_count_after).to eq events_count_before + 1
    expect(issue.unread?(user2)).to eq false
    expect(issue.unread?(user3)).to eq true
  end

end
