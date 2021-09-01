require 'easy_extensions/spec_helper'

describe Issue, logged: :admin do
  let(:issue) { FactoryBot.create(:issue, easy_email_to: nil) }

  context 'sla recalculate' do
    let(:issue) { FactoryBot.create(:issue, start_date: Date.today, due_date: Date.today) }
    let(:issue_status) { FactoryBot.create(:issue_status) }
    let(:sla) { FactoryBot.create(:easy_helpdesk_project_sla, hours_to_solve: 24) }

    def mock_issue
      allow(issue).to receive(:maintained_by_easy_helpdesk?).and_return(true)
      allow(issue).to receive(:easy_helpdesk_project_sla_from_project).and_return(sla)
    end

    it 'due_date > start_date' do
      now = Date.new(2015, 2, 4)
      with_time_travel(0, now: now.to_time) do
        mock_issue
        new_date = Date.today + 2.days
        issue.start_date = new_date
        issue.due_date = new_date
        issue.status_id = issue_status.id
        expect(issue.save).to eq(true)
        expect(issue.due_date >= issue.start_date).to eq(true)
      end
    end

    it 'shift due_date' do
      now = Date.new(2015, 2, 4)
      with_time_travel(0, now: now.to_time) do
        mock_issue
        issue.status_id = issue_status.id
        expect(issue.save).to eq(true)
        expect(issue.due_date).to eq((issue.created_on.localtime + sla.hours_to_solve.hours).to_date)
      end
    end
  end

  context 'easy_email_to validated before send external mail' do

    before do
      allow(issue).to receive(:maintained_by_easy_helpdesk?).and_return(true)
    end

    it 'invalid' do
      issue.easy_helpdesk_mail_template = 2 # id
      expect(issue.valid?).to be_falsey
      expect(issue.errors[:easy_email_to]).to include('cannot be blank')
    end

    it 'valid' do
      allow(issue).to receive(:maintained_by_easy_helpdesk?).and_return(false)
      issue.easy_helpdesk_mail_template = 2 # id
      issue.easy_email_to = 'test@test.com'
      expect(issue.valid?).to be_truthy
    end

    it 'valid no sending' do
      allow(issue).to receive(:maintained_by_easy_helpdesk?).and_return(false)
      issue.easy_email_to = 'test@test.com'
      expect(issue.valid?).to be_truthy
    end
  end

end
