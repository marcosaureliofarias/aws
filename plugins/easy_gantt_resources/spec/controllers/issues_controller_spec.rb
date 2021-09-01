require 'easy_extensions/spec_helper'

RSpec.describe IssuesController, logged: :admin do

  let(:project) { FactoryBot.create(:project) }
  let(:issue1) { FactoryBot.create(:issue, start_date: Date.new(2019, 1, 1),
                                           due_date: Date.new(2019, 1, 14),
                                           estimated_hours: 30,
                                           assigned_to: User.current,
                                           project: project) }
  let(:issue2) { FactoryBot.create(:issue, start_date: Date.new(2019, 2, 1),
                                           due_date: Date.new(2019, 2, 14),
                                           estimated_hours: 30,
                                           assigned_to: User.current,
                                           project: project) }

  it 'Watchdog' do
    with_easy_settings({ easy_gantt_resources_watchdog_enabled: true }, project) do
      subject.instance_variable_set(:@issue, issue1)

      # No overload of asignee
      subject.gantt_resources_messages
      expect(subject.flash[:error]).to be_nil

      # Prepare for overload
      issue1.easy_gantt_resources.delete_all
      issue1.easy_gantt_resources.create!(date: Date.new(2019, 1, 1), hours: 16, user_id: issue1.assigned_to.id)
      issue1.easy_gantt_resources.create!(date: Date.new(2019, 1, 2), hours: 0, user_id: issue1.assigned_to.id)
      issue1.easy_gantt_resources.create!(date: Date.new(2019, 1, 4), hours: 16, user_id: issue1.assigned_to.id)
      issue1.easy_gantt_resources.reload

      issue2.easy_gantt_resources.delete_all
      issue2.easy_gantt_resources.create!(date: Date.new(2019, 1, 1), hours: 16, user_id: issue2.assigned_to.id)
      issue2.easy_gantt_resources.create!(date: Date.new(2019, 1, 2), hours: 16, user_id: issue2.assigned_to.id)
      issue2.easy_gantt_resources.create!(date: Date.new(2019, 1, 3), hours: 16, user_id: issue2.assigned_to.id)
      issue2.easy_gantt_resources.create!(date: Date.new(2019, 1, 4), hours: 16, user_id: issue2.assigned_to.id)
      issue2.easy_gantt_resources.reload

      # 1.1. and 4.1. are overloading
      # at 2.1. and 3.1. user is not overloaded by `issue1`
      subject.gantt_resources_messages

      expect(subject.flash[:error]).to include('2019-01-01')
      expect(subject.flash[:error]).to_not include('2019-01-02')
      expect(subject.flash[:error]).to_not include('2019-01-03')
      expect(subject.flash[:error]).to include('2019-01-04')
    end
  end

end
