require 'easy_extensions/spec_helper'

describe 'service-level agreement', logged: :admin do
  let(:sla) { FactoryBot.create(:easy_helpdesk_project_sla) }
  let(:working_time_sla) { FactoryBot.create(:working_time_easy_helpdesk_project_sla) }
  let(:working_time_sla_with_minutes) { FactoryBot.create(:working_time_easy_helpdesk_project_sla, hours_mode_from: '07:30', hours_mode_to: '16:30') }

  let(:status) { FactoryBot.create(:issue_status)}
  let(:issue) { FactoryBot.create(:issue, project: sla.easy_helpdesk_project.project, priority: sla.priority, status: status ) }
  let(:working_time_issue) { FactoryBot.create(:issue, project: working_time_sla.easy_helpdesk_project.project, priority: working_time_sla.priority ) }
  let(:working_time_issue2) { FactoryBot.create(:issue, project: working_time_sla_with_minutes.easy_helpdesk_project.project, priority: working_time_sla_with_minutes.priority ) }

  it 'should use standard sla' do
    start = issue.created_on.localtime
    expect(issue.maintained_by_easy_helpdesk?).to be true
    expected_reponse_time = start.to_time + sla.hours_to_response.hours
    expect(issue.easy_response_date_time.localtime).to eq expected_reponse_time
  end

  it 'should use sla with working time' do
    skip("dates accross winter/summer time") if Date.today.to_time.gmt_offset != (Date.today + 3.days).to_time.gmt_offset
    calendar = working_time_sla.easy_user_working_time_calendar
    calendar.holidays.build(holiday_date: Date.today, name: 'holiday1', ical_uid: '1')
    calendar.holidays.build(holiday_date: Date.today + 2.days, name: 'holiday2', ical_uid: '2')
    calendar.working_week_days = (1..7).to_a
    calendar.save
    expect(working_time_issue.maintained_by_easy_helpdesk?).to be true
    expected_reponse_time = ((working_time_issue.created_on.localtime.to_date + 3.days).to_time + working_time_sla.hours_mode_from.to_f.hours + 1.hour).localtime
    working_time_issue.reload
    expect(working_time_issue.easy_response_date_time.localtime).to eq expected_reponse_time
  end

  it 'should use sla with working time with minutes' do
    skip("dates accross winter/summer time") if Date.today.to_time.gmt_offset != (Date.today + 3.days).to_time.gmt_offset
    calendar = working_time_sla_with_minutes.easy_user_working_time_calendar
    calendar.holidays.build(holiday_date: Date.today, name: 'holiday1', ical_uid: '1')
    calendar.holidays.build(holiday_date: Date.today + 2.days, name: 'holiday2', ical_uid: '2')
    calendar.working_week_days = (1..7).to_a
    calendar.save
    expect(working_time_issue2.maintained_by_easy_helpdesk?).to be true
    expected_reponse_time = ((working_time_issue2.created_on.localtime.to_date + 3.days).to_time + (7.5).hours + 1.hour).localtime
    working_time_issue2.reload
    expect(working_time_issue2.easy_response_date_time.localtime).to eq expected_reponse_time
  end

  context 'waiting for client' do
    include_context 'sla support'

    it 'should suspend sla' do
      with_sla_stop_start_states_settings do
        expect(issue.maintained_by_easy_helpdesk?).to be true

        expect(issue.easy_time_to_solve_paused?).to be false

        issue.update_attribute(:status_id, stop_status.id)
        expect(issue.easy_time_to_solve_paused?).to be true
        issue.update_attribute(:status_id, start_status.id)
        expect(issue.easy_time_to_solve_paused?).to be false
      end
    end

    it 'should not suspend sla' do
      with_sla_stop_start_states_settings do
        expect(issue.maintained_by_easy_helpdesk?).to be true

        expect(issue.easy_time_to_solve_paused?).to be false

        issue.update_attribute(:status_id, start_status.id)
        expect(issue.easy_time_to_solve_paused?).to be false
      end
    end

    it 'should update easy_response_date_time' do
      skip("dates accross winter/summer time") if Date.today.to_time.gmt_offset != (Date.today + 2.days).to_time.gmt_offset
      with_sla_stop_start_states_settings do
        expect(issue.maintained_by_easy_helpdesk?).to be true
        expect(issue.easy_time_to_solve_paused?).to be false

        response = issue.created_on + sla.hours_to_response.hours

        issue.update_attribute(:status_id, stop_status.id)
        expect(issue.easy_time_to_solve_paused?).to be true
        expect(issue.easy_response_date_time).to be_within(10.second).of response
        with_time_travel(1.day) do
          issue.update_attribute(:status_id, start_status.id)
          expect(issue.easy_time_to_solve_paused?).to be false
          expect(issue.easy_response_date_time).to be_within(10.second).of response + 1.day
        end
      end
    end
  end

  context 'recalculate due date after SLA suspended' do
    include_context "sla support"
    it 'due_date after client waiting should be prolonged' do
      with_sla_stop_start_states_settings do
        resolve_time = issue.created_on.localtime + sla.hours_to_solve.hours
        expect(issue.easy_due_date_time).to eq(resolve_time)
        issue.update_attribute(:status_id, stop_status.id)
        expect(issue.easy_time_to_solve_paused?).to be true

        with_time_travel(2.days) do
          issue.update_attribute(:status_id, start_status.id)
          expect(issue.easy_time_to_solve_paused?).to be false
          expect(issue.easy_due_date_time).to be_within(10.second).of resolve_time + 2.days
          expect(issue.due_date).to eq resolve_time.to_date + 2.days
        end
      end
    end

    it 'due_date localtime fix' do
      with_sla_stop_start_states_settings do
        time_now = Time.now.midnight - (Time.now.utc_offset / 3600).hours
        with_time_travel(0.days, now: time_now) { issue }
        resolve_time = issue.created_on.localtime + sla.hours_to_solve.hours

        with_time_travel(0.days, now: time_now) { issue.update_attribute(:status_id, stop_status.id) }

        with_time_travel(2.days, now: time_now) do
          issue.update_attribute(:status_id, start_status.id)
          expect(issue.due_date).to eq resolve_time.to_date + 2.days
        end
      end
    end
  end
end
