require 'easy_extensions/spec_helper'

describe EasyAutoCompletesController, type: :request, logged: :admin do

  context '#issue_allocation_data' do
    let(:start_date) { Date.parse("2020-01-01") }
    let(:due_date) { Date.parse("2020-01-07") }
    let(:user) { FactoryBot.create(:user) }
    let!(:issue_no_date_limit) { FactoryBot.create(:issue, assigned_to: user, start_date: nil, due_date: nil) }
    let!(:issue_start_date) { FactoryBot.create(:issue, assigned_to: user, start_date: start_date, due_date: nil) }
    let!(:issue_due_date) { FactoryBot.create(:issue, assigned_to: user, start_date: nil, due_date: due_date) }
    let!(:issue_start_date_due_date) { FactoryBot.create(:issue, assigned_to: user, start_date: start_date, due_date: due_date) }
    let!(:issue_out_of_bounds) { FactoryBot.create(:issue, assigned_to: user, start_date: start_date.increase_date(1.day), due_date: due_date.increase_date(-1.day)) }

    it 'all issues' do
      get '/easy_autocompletes/easy_scheduler_issues', params: {format: 'json', user_id: user.id}
      expect(assigns[:entities].length).to eq(5)
    end

    it 'start_date' do
      get '/easy_autocompletes/easy_scheduler_issues', params: {format: 'json', user_id: user.id, start_date: start_date}
      expect(assigns[:entities].length).to eq(4)
      expect(assigns[:entities]).not_to include(issue_out_of_bounds)

      get '/easy_autocompletes/easy_scheduler_issues', params: {format: 'json', user_id: user.id, start_date: start_date.increase_date(-1.day)}
      expect(assigns[:entities].length).to eq(2)
      expect(assigns[:entities]).not_to include(issue_start_date) # not started yet
    end

    it 'due_date' do
      get '/easy_autocompletes/easy_scheduler_issues', params: {format: 'json', user_id: user.id, due_date: due_date}
      expect(assigns[:entities].length).to eq(4)
      expect(assigns[:entities]).not_to include(issue_out_of_bounds)

      get '/easy_autocompletes/easy_scheduler_issues', params: {format: 'json', user_id: user.id, due_date: due_date.increase_date(1.day)}
      expect(assigns[:entities].length).to eq(2)
      expect(assigns[:entities]).not_to include(issue_due_date) # already ended
    end

    it 'start_date / due_date' do
      get '/easy_autocompletes/easy_scheduler_issues', params: {format: 'json', user_id: user.id, start_date: start_date, due_date: due_date}
      expect(assigns[:entities].length).to eq(4)
      expect(assigns[:entities]).not_to include(issue_out_of_bounds)

      get '/easy_autocompletes/easy_scheduler_issues', params: {format: 'json', user_id: user.id, start_date: start_date.increase_date(-1.day), due_date: due_date.increase_date(1.day)}
      expect(assigns[:entities].length).to eq(1)
      expect(assigns[:entities]).to include(issue_no_date_limit)
    end

  end

end