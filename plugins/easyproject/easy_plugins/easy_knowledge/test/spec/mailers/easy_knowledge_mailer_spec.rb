require 'easy_extensions/spec_helper'

describe EasyKnowledgeMailer, type: :mailer do

  let(:user) { FactoryBot.create(:user) }
  let(:easy_knowledge_story) { FactoryBot.create(:easy_knowledge_story, author: user) }

  around(:each) do |example|
    with_user_pref(no_notification_ever: false) do
      example.run
    end
  end

  context '#easy_knowledge_story_added' do
    it 'email is sent' do
      allow(easy_knowledge_story).to receive(:recipients).and_return([user])

      expect {
        EasyKnowledgeMailer.deliver_easy_knowledge_story_added(easy_knowledge_story)
      }.to enqueue_job
    end

    it 'email content' do
      mail = EasyKnowledgeMailer.easy_knowledge_story_added(user, easy_knowledge_story)
      expect(mail.subject).to match I18n.t(:label_easy_knowledge)
    end
  end

  context '#recommended_story_updated' do
    it 'email is sent' do
      recipients = [user]
      allow(EasyKnowledgeMailer).to receive(:valid_recipients).and_return(recipients)

      expect {
        EasyKnowledgeMailer.deliver_recommended_story_updated(easy_knowledge_story)
      }.to have_enqueued_job(ActionMailer::DeliveryJob).at_least(recipients.count).times
    end

    it 'email content' do
      mail = EasyKnowledgeMailer.recommended_story_updated(user, easy_knowledge_story)
      expect(mail.subject).to match I18n.t(:label_easy_knowledge)
    end
  end

  context '#recommended_stories' do
    it 'email is sent' do
      allow(easy_knowledge_story).to receive(:recipients).and_return([user])

      expect {
        EasyKnowledgeMailer.deliver_recommended_stories([easy_knowledge_story], [user])
      }.to enqueue_job
    end

    it 'email content' do
      mail = EasyKnowledgeMailer.recommended_stories(user, [easy_knowledge_story], user)
      expect(mail.subject).to match I18n.t(:label_easy_knowledge)
    end
  end

end
