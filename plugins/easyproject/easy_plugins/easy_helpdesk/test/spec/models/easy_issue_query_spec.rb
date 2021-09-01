require 'easy_extensions/spec_helper'

describe 'EasyIssueQuery', logged: :admin do
  context 'easy_response_date_time filter' do

    def create_ticket_expires_after(hours)
      FactoryGirl.create(:issue, easy_response_date_time: User.current.user_time_in_zone + hours.hours)
    end

    it 'easy_helpdesk_time_to_response' do
      issue = create_ticket_expires_after(2)
      query = EasyIssueQuery.new
      query.add_filter("easy_helpdesk_time_to_response", '=', ['3'])
      expect(query.entities.to_a).to be_empty
      query.add_filter("easy_helpdesk_time_to_response", '=', ['2'])
      expect(query.entities.to_a).to eq([issue])
      query.add_filter("easy_helpdesk_time_to_response", '>=', ['1'])
      expect(query.entities.to_a).to eq([issue])
      query.add_filter("easy_helpdesk_time_to_response", '>=', ['3'])
      expect(query.entities.to_a).to be_empty
      query.add_filter("easy_helpdesk_time_to_response", '><', ['1', '3'])
      expect(query.entities.to_a).to eq([issue])
      query.add_filter("easy_helpdesk_time_to_response", '*', [])
      expect(query.entities.to_a).to eq([issue])
      query.add_filter("easy_helpdesk_time_to_response", '!*', [])
      expect(query.entities.to_a).to be_empty
    end

    it 'easy_helpdesk_time_to_response <= operator' do
      issue = create_ticket_expires_after(-6)
      query = EasyIssueQuery.new
      query.add_filter("easy_helpdesk_time_to_response", '<=', ['2'])
      expect(query.entities.to_a).to eq([issue])
    end

    it 'bug fix correct date clause' do
      User.current.pref.time_zone = 'Berlin'
      issue = create_ticket_expires_after(-2.66)
      issue1 = create_ticket_expires_after(-1)
      query = EasyIssueQuery.new
      query.add_filter("easy_helpdesk_time_to_response", '><', ['-3', '-2'])
      expect(query.entities.to_a).to eq([issue])
      query.add_filter("easy_helpdesk_time_to_response", '=', ['-2'])
      expect(query.entities.to_a).to be_empty
      query.add_filter("easy_helpdesk_time_to_response", '=', ['-1'])
      expect(query.entities.to_a).to eq([issue1])
      query.add_filter("easy_helpdesk_time_to_response", '>=', ['-2'])
      expect(query.entities.to_a).to eq([issue1])
      query.add_filter("easy_helpdesk_time_to_response", '<=', ['-2'])
      expect(query.entities.to_a).to eq([issue])
    end
  end
end
