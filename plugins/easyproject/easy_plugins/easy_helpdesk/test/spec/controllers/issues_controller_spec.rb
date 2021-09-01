require 'easy_extensions/spec_helper'

describe IssuesController, logged: :admin do

  let(:user1) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }
  let(:group) { FactoryGirl.create(:group, users: [user1]) }
  let(:project) { FactoryGirl.create(:project, members: [user2]) }
  let(:member_group) { FactoryGirl.create(:member, project: project, principal: group) }
  let(:easy_helpdesk_project) { FactoryGirl.create(:easy_helpdesk_project, project: project, watchers_ids: [user1.id.to_s, user2.id.to_s], watcher_groups_ids: [group.id.to_s]) }

  describe 'new issue with default coworkers' do
    it 'default users and group coworkers where an user is member of group' do
      member_group
      easy_helpdesk_project

      expect{ post :create, params: {issue: { project_id: project.id, subject: 'test helpdesk coworkers' } } }.to change(Issue, :count).by(1)
      issue = assigns(:issue)

      expect(issue.watcher_user_ids).to eq([user2.id])
      expect(issue.watcher_group_ids).to eq([group.id])
      expect(issue.watchers.map{|w| w.user_id}).to include(user1.id, user2.id, group.id)
    end
  end

  describe 'bulk update' do
    let(:issue) { FactoryBot.create(:issue, project: project) }
    let(:issue2) { FactoryBot.create(:issue, project: project) }
    let(:test_user) { FactoryBot.create(:user) }

    context 'easy_helpdesk_ticket_owner_id' do
      before do
        allow_any_instance_of(Tracker).to receive(:fields_bits).and_return(0)
      end

      it 'should change both issues' do
        easy_helpdesk_project
        put :bulk_update, params: {ids: [issue.id, issue2.id], issue: {easy_helpdesk_ticket_owner_id: test_user.id}}
        i1 = Issue.find(issue.id); i2 = Issue.find(issue2.id)
        expect(i1.easy_helpdesk_ticket_owner_id).to eq(test_user.id)
        expect(i2.easy_helpdesk_ticket_owner_id).to eq(test_user.id)
      end

      it 'should change if maintained_by_easy_helpdesk' do
        easy_helpdesk_project
        issue3 = FactoryBot.create(:issue)
        put :bulk_update, params: {ids: [issue.id, issue3.id], issue: {easy_helpdesk_ticket_owner_id: user2.id}}
        i1 = Issue.find(issue.id); i3 = Issue.find(issue3.id)
        expect(i1.easy_helpdesk_ticket_owner_id).to eq(user2.id)
        expect(i3.easy_helpdesk_ticket_owner_id).to eq(nil)
      end
    end
  end

  describe 'update' do
    context 'quick send external mail' do
      include_context 'easy_helpdesk_send_quick_external_mail'
      it 'shouldnt send mail if not maintained_by_easy_helpdesk' do
        allow(issue).to receive(:maintained_by_easy_helpdesk?).and_return(false)
        expect { put :update, params: {id: issue, issue: { subject: "UPDATED", easy_helpdesk_mail_template: '1' }} }.not_to change { EasyExternalMailer.deliveries.count }
      end

      it 'shouldnt send mail if easy_email_to empty' do
        allow(issue).to receive(:easy_email_to).and_return('')
        expect { put :update, params: {id: issue, issue: { subject: "UPDATED", easy_helpdesk_mail_template: '1' }} }.not_to change { EasyExternalMailer.deliveries.count }
      end

      it 'should send to customer' do
        easy_helpdesk_mail_template
        expect { put :update, params: {id: issue, issue: { subject: "UPDATED", easy_helpdesk_mail_template: easy_helpdesk_mail_template.id }} }.to change { EasyExternalMailer.deliveries.count }.by(1)
      end

      it 'should attach inline images to email' do
        easy_helpdesk_mail_template
        comment = IO.read(File.join(EasyExtensions::EASY_EXTENSIONS_DIR + '/test/fixtures/files', 'inline_image.html'))
        expect(EasyExtensions::ExternalMailSender).to receive(:call).with(
          kind_of(Issue),
          kind_of(EasyExtensions::EasyMailTemplateIssue),
          hash_including(attachments: [kind_of(Attachment)], journal: kind_of(Journal))
        )
        expect { put :update, params: {id: issue, issue: { easy_helpdesk_mail_template: easy_helpdesk_mail_template.id, notes: comment }} }.to change { Attachment.count }.by(1)
      end

      it 'should send mail if no task updates' do
        easy_helpdesk_mail_template
        expect { put :update, params: {id: issue, issue: { easy_helpdesk_mail_template: easy_helpdesk_mail_template.id }} }.to change { EasyExternalMailer.deliveries.count }.by(1)
      end

      it 'redirects to original_back_url, both options selected' do
        put :update, params: {id: issue, issue: { subject: "UPDATED", send_to_external_mails: '1',  easy_helpdesk_mail_template: '1' }}
        expect(response.header["Location"]).to eq(Addressable::URI.escape(issue_url(issue)))
      end
    end
  end

end
