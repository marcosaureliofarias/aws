require 'easy_extensions/spec_helper'

describe 'epm issue query', logged: :admin do
  context 'sort' do
    it 'adhoc default' do
      q = EpmIssueQuery.new.get_query({ 'query_type' => '2' }, User.current)
      expect(q.sort_criteria).to eq([["priority", "desc"], ["due_date", "asc"], ["parent", "asc"]])
    end

    it 'saved default' do
      easy_issue_query = FactoryBot.create(:easy_issue_query)
      q                = EpmIssueQuery.new.get_query({ 'query_id' => easy_issue_query.id }, User.current)
      expect(q.sort_criteria).to eq([["priority", "desc"], ["due_date", "asc"], ["parent", "asc"]])
    end

    it 'saved custom' do
      easy_issue_query = FactoryBot.create(:easy_issue_query, sort_criteria: [['subject', 'desc'], ['status', 'asc']])
      q                = EpmIssueQuery.new.get_query({ 'query_id' => easy_issue_query.id }, User.current)
      expect(q.sort_criteria).to eq([["subject", "desc"], ["status", "asc"]])
    end

    it 'saved override' do
      easy_issue_query = FactoryBot.create(:easy_issue_query, sort_criteria: [['subject', 'desc'], ['status', 'asc']])
      q                = EpmIssueQuery.new.get_query({ 'query_id' => easy_issue_query.id, 'sort' => 'subject:asc' }, User.current)
      expect(q.sort_criteria).to eq([["subject", "asc"]])
    end

    it 'does not override sort criteria of saved query' do
      saved_query_sort_criteria = [['subject', 'desc'], ['status', 'asc']]
      easy_issue_query = FactoryBot.create(:easy_issue_query, sort_criteria: saved_query_sort_criteria)
      epm_settings = { 'query_id' => easy_issue_query.id,
                       'sort_criteria' => ['status', 'asc'],
                       'query_type' => '1'}
      q = EpmIssueQuery.new.get_query(epm_settings, User.current)
      expect(q.sort_criteria).to eq(saved_query_sort_criteria)
    end
  end
end
