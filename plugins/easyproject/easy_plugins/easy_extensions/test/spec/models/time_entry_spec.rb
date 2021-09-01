require 'easy_extensions/spec_helper'

describe TimeEntry do
  let(:user) { FactoryBot.create(:user) }
  let!(:project) { FactoryBot.create(:project, number_of_issues: 1, members: [user]) }
  let!(:project_without_time_entries) { FactoryBot.create(:project, number_of_issues: 1, members: [user]) }
  let(:easy_global_time_entry_setting) { FactoryBot.create(:easy_global_time_entry_setting, role_id: user.roles.first.id) }
  let(:time_entry_current) { FactoryBot.build(:time_entry, :current, user_id: user.id, project_id: project.id, issue_id: project.issues.first.id) }
  let(:time_entry_current_ten_days_new) { FactoryBot.build(:time_entry, :current, user_id: user.id, spent_on: Date.today + 10.day) }
  let(:time_entry_old) { FactoryBot.build(:time_entry, :old, user_id: user.id, project_id: project.id, issue_id: project.issues.first.id) }
  let(:time_entry_future) { FactoryBot.build(:time_entry, :future, user_id: user.id, project_id: project.id, issue_id: project.issues.first.id) }
  let(:locked_time_entry) { FactoryBot.build(:time_entry, user_id: user.id, project_id: project.id, issue_id: project.issues.first.id, easy_locked: true) }
  let(:project_template) { FactoryBot.create(:project, :template, number_of_issues: 1, members: [user]) }
  let(:time_entry_project_template) { FactoryBot.build(:time_entry, user_id: user.id, project_id: project_template.id, issue_id: project_template.issues.first.id, activity_id: project_template.project_time_entry_activities.first.id) }

  it 'respects limits' do
    with_current_user(user) do
      expect(user.roles_for_project(project).empty?).to eq(false)
      expect(easy_global_time_entry_setting.valid?).to eq(true)
      expect(time_entry_current.valid?).to eq(true)
      expect(time_entry_current_ten_days_new.valid?).to eq(true)
      expect(time_entry_old.valid?).to eq(false)
      expect(time_entry_future.valid?).to eq(false)
    end
  end

  it 'respects create limits' do
    with_current_user(user) do
      expect(user.roles_for_project(project).empty?).to eq(false)

      easy_global_time_entry_setting.spent_on_limit_before_today      = 2
      easy_global_time_entry_setting.spent_on_limit_before_today_edit = 10
      easy_global_time_entry_setting.save

      expect(time_entry_old.valid?).to eq(false)

      easy_global_time_entry_setting.spent_on_limit_before_today      = 10
      easy_global_time_entry_setting.spent_on_limit_before_today_edit = 10
      easy_global_time_entry_setting.save

      expect(time_entry_old.valid?).to eq(true)
    end
  end

  it 'respects edit limits' do
    with_current_user(user) do
      expect(user.roles_for_project(project).empty?).to eq(false)
      time_entry_old.save(:validate => false)

      easy_global_time_entry_setting.spent_on_limit_before_today      = 10
      easy_global_time_entry_setting.spent_on_limit_before_today_edit = 2
      easy_global_time_entry_setting.save

      expect(time_entry_old.valid?).to eq(false)

      easy_global_time_entry_setting.spent_on_limit_before_today      = 10
      easy_global_time_entry_setting.spent_on_limit_before_today_edit = 10
      easy_global_time_entry_setting.save

      expect(time_entry_old.valid?).to eq(true)
    end
  end

  context 'daily limit' do
    let(:easy_global_time_entry_setting) { FactoryBot.create(:easy_global_time_entry_setting,
        role_id: user.roles.first.id,
        spent_on_limit_before_today: nil,
        spent_on_limit_before_today_edit: nil,
        spent_on_limit_after_today: nil,
        spent_on_limit_after_today_edit: nil
    )}

    it 'different days' do
      with_current_user(user) do
        easy_global_time_entry_setting.time_entry_daily_limit = 2
        easy_global_time_entry_setting.save
        time_entry_current.hours = 1
        time_entry_current.save!
        time_entry_old.save!
        time_entry_old.hours = 2
        expect(time_entry_old.valid?).to eq(true)
      end
    end

    it 'over limit' do
      with_current_user(user) do
        easy_global_time_entry_setting.time_entry_daily_limit = 2
        easy_global_time_entry_setting.save
        time_entry_current.hours = 1
        time_entry_current.save!
        time_entry_old.save!
        time_entry_old.spent_on = time_entry_current.spent_on
        time_entry_old.hours = 2
        expect(time_entry_old.valid?).to eq(false)
      end
    end

    it 'within limit' do
      with_current_user(user) do
        easy_global_time_entry_setting.time_entry_daily_limit = 4
        easy_global_time_entry_setting.save
        time_entry_current.hours = 1
        time_entry_current.save!
        time_entry_old.save!
        time_entry_old.spent_on = time_entry_current.spent_on
        time_entry_old.hours = 1
        expect(time_entry_old.valid?).to eq(true)
      end
    end
  end

  it 'doesnt allow to change an old entry' do
    with_current_user(user) do
      time_entry_old.save(:validate => false)
      easy_global_time_entry_setting.spent_on_limit_before_today_edit = 2
      easy_global_time_entry_setting.save
      expect(time_entry_old.valid?).to eq(false)
      time_entry_old.spent_on = Date.today
      expect(time_entry_old.valid?).to eq(false)
    end
  end

  it 'respects no limits' do
    with_current_user(user) do
      expect(user.roles_for_project(project).empty?).to eq(false)

      easy_global_time_entry_setting.spent_on_limit_before_today      = nil
      easy_global_time_entry_setting.spent_on_limit_before_today_edit = 2
      easy_global_time_entry_setting.save
      expect(time_entry_old.valid?).to eq(true)

      time_entry_old.save(:validate => false)

      easy_global_time_entry_setting.spent_on_limit_before_today      = 2
      easy_global_time_entry_setting.spent_on_limit_before_today_edit = nil
      easy_global_time_entry_setting.save

      expect(time_entry_old.valid?).to eq(true)
    end
  end

  it 'can remove project with locked time entry' do
    locked_time_entry.save
    project.reload
    expect { project.destroy }.to change(Project, :count).by(-1)
  end

  it 'can validate time_entry without spent_on field', :logged => true do
    time_entry_current.spent_on = nil
    expect(time_entry_current.should_validate_time_entry_for_workers?).to eq(true)
    expect(time_entry_current.valid?).to eq(false)
  end

  it 'can validate time_entry without user_id field', logged: :admin do
    expect(FactoryBot.build(:time_entry, user: nil, project: project, issue: project.issues.first).valid?).to eq(false)
  end

  context 'visibility', :logged => true do
    it 'visible' do
      expect(time_entry_current.visible?).to eq(false)
      Role.non_member.add_permission! :view_time_entries
      User.current.pref.global_time_entries_visibility = true
      User.current.pref.save
      User.current.reload
      expect(time_entry_current.visible?).to eq(true)
    end

    it 'visible scope' do
      time_entry_current.save
      expect(TimeEntry.visible.count).to eq(0)
      Role.non_member.add_permission! :view_time_entries
      User.current.pref.global_time_entries_visibility = true
      User.current.pref.save
      User.current.reload
      expect(TimeEntry.visible.count).to eq(1)
    end
  end

  it 'validates issue_id', skip: !EasyAttendance.enabled? do
    easy_global_time_entry_setting.required_issue_id_at_time_entry = true
    easy_global_time_entry_setting.save

    time_entry_current.issue_id = nil

    # issue_id must be filled
    time_entry_current.valid?

    expect(time_entry_current).not_to be_valid
    expect(time_entry_current.errors[:issue_id]).to include('cannot be blank')

    # must be skipped
    time_entry_current.easy_attendance = FactoryBot.create(:easy_attendance)
    time_entry_current.valid?

    expect(time_entry_current).to be_valid
  end

  it 'validates comments', skip: !EasyAttendance.enabled? do
    easy_global_time_entry_setting.required_time_entry_comments = true
    easy_global_time_entry_setting.save

    time_entry_current.comments = nil

    # comments must be filled
    time_entry_current.valid?

    expect(time_entry_current).not_to be_valid
    expect(time_entry_current.errors[:comments]).to include('cannot be blank')

    # must be skipped
    time_entry_current.easy_attendance = FactoryBot.create(:easy_attendance)
    time_entry_current.valid?

    expect(time_entry_current).to be_valid
  end

  it 'can not be created for a template project' do
    expect(time_entry_project_template.save).to be(false)
    expect(time_entry_project_template.errors.any?).to be(true)
  end

  it 'can not be valid for destroy with time entries over range' do
    with_current_user(user) do
      time_entry_old.save(validate: false)

      easy_global_time_entry_setting.spent_on_limit_before_today      = 2
      easy_global_time_entry_setting.spent_on_limit_before_today_edit = 2
      easy_global_time_entry_setting.save

      expect(time_entry_old.valid_for_destroy?).to eq(false)

      expect(project.can_delete_project_with_time_entries?).to eq(false)
    end
  end

  it 'can be valid for destroy with time entry in range' do
    with_current_user(user) do
      time_entry_old.save(validate: false)

      easy_global_time_entry_setting.spent_on_limit_before_today      = 10
      easy_global_time_entry_setting.spent_on_limit_before_today_edit = 10
      easy_global_time_entry_setting.save

      expect(time_entry_old.valid_for_destroy?).to eq(true)

      expect(project.can_delete_project_with_time_entries?).to eq(true)
    end
  end

  it 'can be valid for destroy without time entries' do
    with_current_user(user) do
      expect(project_without_time_entries.can_delete_project_with_time_entries?).to eq(true)
    end
  end
end
