RSpec.describe EpmResourceReport, logged: :admin do

  it 'does not fail with empty settings' do
    expect {
      subject.get_show_data({}, User.new)
    }.to_not raise_error
  end

  it 'get correct data' do
    user = FactoryBot.create(:user)
    user2 = FactoryBot.create(:user)
    project = FactoryBot.create(:project)

    # 1.1.2019 is a Tuesday
    # 10.1.2019 is a Thrsday
    # 5.1., 6.1. is a weekend
    issue = FactoryBot.create(:issue, project: project,
                                      assigned_to: user,
                                      start_date: Date.new(2019, 1, 1),
                                      due_date: Date.new(2019, 1, 10),
                                      estimated_hours: 100)

    issue2 = FactoryBot.create(:issue, project: project,
                                      assigned_to: user,
                                      start_date: Date.new(2019, 1, 1),
                                      due_date: Date.new(2019, 1, 10),
                                      estimated_hours: 100)

    FactoryBot.create(:time_entry, issue: issue,
                                   user: user,
                                   hours: 2,
                                   spent_on: Date.new(2019, 1, 1))

    FactoryBot.create(:time_entry, issue: issue,
                                   user: user,
                                   hours: 2,
                                   spent_on: Date.new(2019, 1, 2))

    show_data = subject.get_show_data({
      'config' => {
        'as_list' => '1',
        'as_chart' => '1',
        'show_capacity' => '1',
        'show_allocations' => '1',
        'show_full_allocations' => '1',
        'show_free_capacity' => '1',
        'show_all_spent_time' => '1',
        'show_allocations_percentage' => '1',
        'period_zoom' => 'day',
        'period_type' => '2',
        'period_from' => '2019-01-01',
        'period_to' => '2019-01-10',
      },
      'issue_query' => {
        'set_filter' => '1',
        'fields' => ['issue_id'],
        'operators' => { 'issue_id' => '=' },
        'values' => { 'issue_id' => [issue.id.to_s] },
      },
      'user_query' => {
        'set_filter' => '1',
        'fields' => ['user_id'],
        'operators' => { 'user_id' => '=' },
        'values' => { 'user_id' => [user.id.to_s] },
      },
      'group_query' => {
        'set_filter' => '1',
        'fields' => ['lastname'],
        'operators' => { 'lastname' => '=' },
        'values' => { 'lastname' => 'just_to_show_nothing' },
      },
    }, User.new)

    # Test period
    expect(show_data[:all_periods].size).to eq(10)
    expect(show_data[:all_periods].minmax).to eq([Date.new(2019, 1, 1), Date.new(2019, 1, 10)])

    # Test users and groups
    expect(show_data[:principals]).to eq([user])

    # Test data
    resources = issue.easy_gantt_resources.index_by(&:date)

    show_data[:data_items].each do |date, date_items|
      item = date_items[user.id]
      expect(item.allocations.to_f).to eq(resources[date]&.hours.to_f)
    end

    expect(show_data[:data_items][Date.new(2019, 1, 1)][user.id].allocations_percentage).to eq(125)
    expect(show_data[:data_items][Date.new(2019, 1, 3)][user.id].allocations_percentage).to eq(100)
    expect(show_data[:data_items][Date.new(2019, 1, 5)][user.id].allocations_percentage).to eq(0)
  end

  it 'with easy meetings', skip: !Redmine::Plugin.installed?(:easy_calendar) do
    user = FactoryBot.create(:user)

    # 2 hours
    EasyMeeting.create!(
      name: 'test 1',
      author: user,
      user_ids: [user.id],
      start_time: Time.new(2019, 1, 2, 10),
      end_time: Time.new(2019, 1, 2, 12)
    )

    # 3 hours
    EasyMeeting.create!(
      name: 'test 2',
      author: user,
      user_ids: [user.id],
      start_time: Time.new(2019, 1, 3, 10),
      end_time: Time.new(2019, 1, 3, 13)
    )

    show_data = subject.get_show_data({
      'config' => {
        'as_list' => '1',
        'show_allocations' => '1',
        'period_zoom' => 'month',
        'period_type' => '2',
        'period_from' => '2019-01-01',
        'period_to' => '2019-01-10',
      },
      'user_query' => {
        'set_filter' => '1',
        'fields' => ['user_id'],
        'operators' => { 'user_id' => '=' },
        'values' => { 'user_id' => [user.id.to_s] },
      },
    }, User.new)

    allocations = show_data[:data_items][Date.new(2019, 1, 1)][user.id].allocations
    expect(allocations).to eq(5)
  end

end if Redmine::Plugin.installed?(:easy_gantt_resources)
