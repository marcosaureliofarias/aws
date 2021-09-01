require 'easy_extensions/spec_helper'

describe 'Compute Aggregated Hours', logged: :admin do

  let(:easy_helpdesk_project) { FactoryGirl.create(:aggregated_easy_helpdesk_project) }
  let(:easy_rake_task_compute_aggregated_hours) { FactoryGirl.create(:easy_rake_task_compute_aggregated_hours) }

  it 'should reset remaining aggregated hours' do
    easy_helpdesk_project.aggregated_hours_last_reset = easy_helpdesk_project.aggregated_hours_start_date - 3.month - 1.day
    easy_helpdesk_project.save
    expect{
      easy_rake_task_compute_aggregated_hours.execute
      easy_helpdesk_project.reload
    }.not_to change(easy_helpdesk_project, :aggregated_hours_remaining)
    expect(easy_helpdesk_project.aggregated_hours_remaining).to eq easy_helpdesk_project.monthly_hours
  end

  it 'should not change remaining aggregated hours' do
    easy_helpdesk_project.aggregated_hours_last_update = easy_helpdesk_project.aggregated_hours_start_date
    easy_helpdesk_project.save
    expect{
      easy_rake_task_compute_aggregated_hours.execute
      easy_helpdesk_project.reload
    }.not_to change(easy_helpdesk_project, :aggregated_hours_remaining)
  end

  it 'should change remaining aggregated hours' do
    easy_helpdesk_project.aggregated_hours_last_update = easy_helpdesk_project.aggregated_hours_start_date - 1.month - 1.day
    easy_helpdesk_project.save
    expect{
      easy_rake_task_compute_aggregated_hours.execute
      easy_helpdesk_project.reload
    }.to change(easy_helpdesk_project, :aggregated_hours_remaining)
    expect(easy_helpdesk_project.aggregated_hours_remaining).to eq(easy_helpdesk_project.monthly_hours * 2)
  end

  it 'should change remaining aggregated hours after two months' do
    easy_helpdesk_project.aggregated_hours_last_update = easy_helpdesk_project.aggregated_hours_start_date - 2.months - 1.day
    easy_helpdesk_project.save
    expect{
      easy_rake_task_compute_aggregated_hours.execute
      easy_helpdesk_project.reload
    }.to change(easy_helpdesk_project, :aggregated_hours_remaining)
    expect(easy_helpdesk_project.aggregated_hours_remaining).to eq(easy_helpdesk_project.monthly_hours * 3)
  end
end
