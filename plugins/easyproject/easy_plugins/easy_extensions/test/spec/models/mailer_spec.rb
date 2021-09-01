#require 'easy_extensions/spec_helper'
require 'easy_extensions/spec_helper'
describe Mailer < ActionMailer::Base, :logged => :admin do

  let!(:issue) { FactoryGirl.create(:issue, :with_journals).reload }
  let(:user) { FactoryGirl.create(:user) }

  #let(:sets) { EasySetting.find_by(name: "issue_mail_subject_style").value = "easy" }
  #let(:mail) { Mailer.get_mail_subject_for_issue_add(issue) }


  # before(:each) do
  #  EasySetting.find_by(name: "issue_mail_subject_style") == 'easy'
  # end

  # it 'sends emails' do
  #   with_easy_settings(:issue_mail_subject_style => 'Easy (>>> My task - [Project > Project] updated - Subject (Status))') do
  #     Mailer.issue_add(issue, User.current)
  #     mail = ActionMailer::Base.deliveries.last
  #     expect(mail.subject).to eq("jdksladj")
  #   end
  # end

  it 'sends emails' do
    with_easy_settings(:issue_mail_subject_style => "easy") do
      with_deliveries do
        Mailer.deliver_issue_add(issue)
      end
      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to include(issue.subject)
    end
  end
end
