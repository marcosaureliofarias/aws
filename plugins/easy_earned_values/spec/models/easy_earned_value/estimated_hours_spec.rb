require 'easy_extensions/spec_helper'

RSpec.describe EasyEarnedValue::EstimatedHours do

  before(:each) do |example|
    now = Time.new(2019, 8, 23)

    allow(Time).to receive(:now).and_return(now)
    allow(Date).to receive(:today).and_return(now.to_date)
    allow(DateTime).to receive(:now).and_return(now.to_datetime)
  end

  after(:each) do |example|
    allow(Time).to receive(:now).and_call_original
    allow(Date).to receive(:today).and_call_original
    allow(DateTime).to receive(:now).and_call_original
  end

  def create_project(parent:)
    FactoryBot.create(:project,
      number_of_issues: 0,
      number_of_subprojects: 0,
      add_modules: [:easy_earned_values],
      trackers: [tracker],
      members: [user],
      parent: parent
    )
  end

  def create_issue_base(project:, start_date_day:, due_date_day:, estimated_hours:, done_ratio:)
    @issue = FactoryBot.create(:issue,
      project: project,
      author: user,
      assigned_to: user,
      start_date: Date.new(2019, 8, start_date_day),
      due_date: Date.new(2019, 8, due_date_day),
      estimated_hours: estimated_hours,
      done_ratio: done_ratio,
    )

    # The issue should not be taken into account if it didn't exist that time
    @issue.update_column(:created_on, Date.new(2019, 8, 19))
  end

  def create_journal(day:)
    @journal = @issue.journals.create!(created_on: Date.new(2019, 8, day))
  end

  def create_detail(key, old_value:, value:)
    @journal.details.create!(property: 'attr', prop_key: key, old_value: old_value.to_s, value: value.to_s)
  end

  def create_time_entry(hours, day:)
    @issue.time_entries.create!(activity: @issue.project.activities.first, user: user, spent_on: Date.new(2019, 8, day), hours: hours)
  end

  # State at the end of the day
  #
  #         +------+------+------+------+------+------+------+
  #         |  19  |  20  |  21  |  22  |  23  |  24  |  25  |
  #         +------+------+------+------+------+------+------+
  # est        10h    20h    20h    20h    20h
  # done       0.8    0.8     1      1      1
  # EV          8h    16h    20h    20h    20h
  #
  # log               10h    15h    20h
  # AC          0      10     25     45     45
  #
  def create_issue1
    # Monday to Wednesday
    create_issue_base(project: project, start_date_day: 19, due_date_day: 22, estimated_hours: 20, done_ratio: 100)

    create_journal(day: 19)
    create_detail('done_ratio', old_value: 20, value: 80)
    create_detail('estimated_hours', old_value: 4, value: 10)

    # To check if correct value win
    create_journal(day: 20)
    create_detail('estimated_hours', old_value: 10, value: 16)
    create_journal(day: 20)
    create_detail('estimated_hours', old_value: 16, value: 18)
    create_journal(day: 20)
    create_detail('estimated_hours', old_value: 18, value: 20)

    create_journal(day: 21)
    create_detail('done_ratio', old_value: 80, value: 100)

    create_time_entry(10, day: 20)
    create_time_entry(15, day: 21)
    create_time_entry(20, day: 22)

    @issue
  end

  # State at the end of the day
  #
  #         +------+------+------+------+------+------+------+
  #         |  19  |  20  |  21  |  22  |  23  |  24  |  25  |
  #         +------+------+------+------+------+------+------+
  # est        20h    20h    60h   100h   100h
  # done       0.4    0.4    0.6    0.6    0.8
  # EV          8h     8h    36h    60h    80h
  #
  # log                      20h           20h           20h
  # AC          0      0      20     20     40
  #
  def create_issue2
    # Wednesday to Sunday
    create_issue_base(project: subproject, start_date_day: 21, due_date_day: 25, estimated_hours: 100, done_ratio: 80)

    create_journal(day: 21)
    create_detail('done_ratio', old_value: 40, value: 60)
    create_detail('estimated_hours', old_value: 20, value: 60)

    create_journal(day: 22)
    create_detail('estimated_hours', old_value: 60, value: 100)

    create_journal(day: 23)
    create_detail('done_ratio', old_value: 60, value: 80)

    create_time_entry(20, day: 21)
    create_time_entry(20, day: 23)
    create_time_entry(20, day: 25)

    @issue
  end

  def test_data_item(earned_value, day:, ev:, ac:, pv:)
    data_item = earned_value.data.find {|i| i.date == Date.new(2019, 8, day) }
    expect(data_item).to_not be_nil
    expect(data_item.ev).to eq(ev)
    expect(data_item.ac).to eq(ac)
    expect(data_item.pv).to eq(pv)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:tracker) { FactoryBot.create(:tracker) }
  let(:project) { create_project(parent: nil) }
  let(:subproject) { create_project(parent: project) }
  let(:issue1) { create_issue1 }
  let(:issue2) { create_issue2 }

  it 'without issues' do
    project

    earned_value = described_class.create!(name: 'test', project: project)
    earned_value.reload_all

    expect(earned_value.data.reload).to be_empty
  end

  it 'planned from current project' do
    issue1; issue2

    # Because lft and rgt have changed
    project.reload

    earned_value = described_class.create!(name: 'test', project: project)
    earned_value.reload_all

    expect(earned_value.start_date).to eq(Date.new(2019, 8, 19))
    expect(earned_value.due_date).to eq(Date.new(2019, 8, 25))

    test_data_item(earned_value, day: 19, ev: 16, ac: 0, pv: 5)
    test_data_item(earned_value, day: 20, ev: 24, ac: 10, pv: 10)
    test_data_item(earned_value, day: 21, ev: 56, ac: 45, pv: 35)
    test_data_item(earned_value, day: 22, ev: 80, ac: 65, pv: 60)
    test_data_item(earned_value, day: 23, ev: 100, ac: 85, pv: 80)
    test_data_item(earned_value, day: 24, ev: nil, ac: nil, pv: 100)
    test_data_item(earned_value, day: 25, ev: nil, ac: nil, pv: 120)
    test_data_item(earned_value, day: 26, ev: nil, ac: nil, pv: 120)

    expect(earned_value.project).to eq(project)
    expect(earned_value.baseline).to eq(project)
  end

end
