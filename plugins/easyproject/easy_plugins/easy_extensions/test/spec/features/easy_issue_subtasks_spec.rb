require 'easy_extensions/spec_helper'

feature 'issue distributed tasks', logged: :admin do

  let(:easy_distributed_tasks_tracker) { FactoryGirl.create(:tracker, :easy_distributed_tasks => true) }
  let(:non_easy_distributed_tasks_tracker) { FactoryGirl.create(:tracker, :easy_distributed_tasks => false) }
  let(:project) { FactoryGirl.create(:project, number_of_issues: 1, number_of_members: 4) }

  def add_subtask
    page.execute_script('$("#easy_distributed_tasks_table .icon-add").trigger("click")')
  end

  it 'displays distributed tasks table on new issue form when the tracker is changed to distributed task', js: true do
    project.trackers << easy_distributed_tasks_tracker
    visit new_issue_path(:project_id => project.id)
    expect(page).to have_selector('#easy_distributed_tasks', visible: false)
    select easy_distributed_tasks_tracker.name, :from => 'issue_tracker_id'
    expect(page).to have_selector('#easy_distributed_tasks', visible: true)
  end

  it 'allows user to add multiple distributed tasks', js: true do
    project.trackers << easy_distributed_tasks_tracker
    visit new_issue_path(:project_id => project.id)
    select easy_distributed_tasks_tracker.name, :from => 'issue_tracker_id'
    rows = 1
    3.times do
      wait_for_ajax
      rows += 1
      expect(page).to have_selector('#easy_distributed_tasks_table tbody tr', count: rows)
      add_subtask
    end
  end

  context 'create distributed tasks' do
    def create_issue_with_distributed_tasks(options = {})
      visit new_issue_path(:project_id => project.id)
      page.find('#issue_subject').set('testing')
      select(easy_distributed_tasks_tracker.name, :from => 'issue_tracker_id') unless options[:without_tracker]
      wait_for_ajax
      add_subtask
      tbody = page.find('#easy_distributed_tasks_table tbody')
      tbody.all('select.easy_distributed_task_assigned_to_ids').each { |e| e.select(User.current.name) }
      tbody.all('input.easy_distributed_task_estimated_hours').each { |e| e.set(2) }
      page.find('input[type=submit][name=commit]').click
    end

    it 'should not create tasks without non-distributed tracker', js: true do
      project.trackers = [easy_distributed_tasks_tracker]
      create_issue_with_distributed_tasks(:without_tracker => true)
      within '#errorExplanation' do
        expect(page).to have_text(I18n.t(:error_cannot_create_distributed_tasks_without_tracker))
      end
    end

    it 'should create distributed tasks, distributed tracker first', js: true do
      project.trackers = [easy_distributed_tasks_tracker, non_easy_distributed_tasks_tracker]
      create_issue_with_distributed_tasks
      expect(page).to have_selector('.flash.notice')
      expect(page).to have_selector('.issue-childs tr.issue.child', count: 2)
    end

    it 'should create distributed tasks, nondistributed tracker first', js: true do
      project.trackers = [non_easy_distributed_tasks_tracker, easy_distributed_tasks_tracker]
      create_issue_with_distributed_tasks
      expect(page).to have_selector('.flash.notice')
      expect(page).to have_selector('.issue-childs tr.issue.child', count: 2)
    end

    it 'should not create distributed tasks without parent issue id', js: true do
      non_easy_distributed_tasks_tracker.core_fields = Tracker::CORE_FIELDS - ['parent_issue_id']
      non_easy_distributed_tasks_tracker.save; non_easy_distributed_tasks_tracker.reload
      project.trackers = [easy_distributed_tasks_tracker, non_easy_distributed_tasks_tracker]
      create_issue_with_distributed_tasks
      within '#errorExplanation' do
        expect(page).to have_text(I18n.t(:error_parent_issue_id_is_disabled))
      end
    end
  end

end
