require 'easy_extensions/spec_helper'

describe 'Replace tokens' do

  let(:all_tokens_text) {
    <<-eos
    Task id: %task_id%
    Task id without hash: %task_id_without_hash%
    Task subject: %task_subject%
    Spent time: %spent_time%
    Asignee: %assignee%
    Task note: %task_note%
    Contact first name: %contact_firstname%
    Contact name: %contact_name%
    Contact last name: %contact_lastname%
    Date: %date%
    Task tracker: %task_tracker%
    Task project: %task_project%
    Task description: %task_description%
    Task status: %task_status%
    Task priority: %task_priority%
    Task estimated hours: %task_estimated_hours%
    Task done ratio: %task_done_ratio%
    Task public url: %task_public_url%
    Task closed on: %task_closed_on%
    Task due date: %task_due_date%
    Task start date: %task_start_date%
    User name: %user_name%
    User first name: %user_first_name%
    User last name: %user_last_name%
    eos
  }
  let!(:issue) { FactoryGirl.create(:issue, due_date: Date.today, closed_on: Time.now) }

  let(:next_generation_tokens) {
    <<-eos
    Task id: %{task_id}
    Task id without hash: %{task_id_without_hash}
    Task subject: %{task_subject}
    Spent time: %{spent_time}
    Asignee: %{assignee}
    Task note: %{task_note}
    Date: %{date}
    Task tracker: %{task_tracker}
    Task project: %{task_project}
    Task description: %{task_description}
    Task status: %{task_status}
    Task priority: %{task_priority}
    Task estimated hours: %{task_estimated_hours}
    Task done ratio: %{task_done_ratio}
    Task public url: %{task_public_url}
    Task closed on: %{task_closed_on}
    Task due date: %{task_due_date}
    Task start date: %{task_start_date}
    User name: %{user_name}
    User first name: %{user_first_name}
    User last name: %{user_last_name}
    eos
  }

  it 'should pass' do
    text = ''
    time = 0.0
    # 100.times do
      time += Benchmark.realtime {text = issue.easy_helpdesk_replace_tokens(all_tokens_text)}
    # end
    # puts time / 100.0
    expect(text).to include "Task id: ##{issue.id}", "Task id without hash: #{issue.id}"
    expect(text).to include "Task subject: #{issue.subject}", "User name: #{User.current.name}"
  end

  xit 'next generation', pending: 'For next generation' do
    text = ''
    time = 0.0
    100.times do
      time += Benchmark.realtime {text = issue.easy_helpdesk_replace_tokens(next_generation_tokens)}
    end
    expect(text).to include "Task id: ##{issue.id}", "Task id without hash: #{issue.id}"
    expect(text).to include "Task subject: #{issue.subject}", "User name: #{User.current.name}"
  end

end
