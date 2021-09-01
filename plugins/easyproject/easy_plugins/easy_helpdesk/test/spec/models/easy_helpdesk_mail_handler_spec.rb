require 'easy_extensions/spec_helper'

describe 'Easy Helpdesk Mail Handler' do

  def submit_email(filename, options = {})
    raw = IO.read(File.join(File.dirname(__FILE__) + '/../../fixtures/easy_helpdesk_mail_handler', filename))
    EasyHelpdeskMailHandler.receive(raw, options)
  end

  def assert_issue_created(issue)
    expect(issue).to be_a Issue # false on error
    expect(issue.new_record?).to be false
    issue.reload
  end

  let!(:easy_helpdesk_project) { FactoryGirl.create(:easy_helpdesk_project) }
  let!(:easy_helpdesk_project_to_easy) { FactoryGirl.create(:easy_helpdesk_project) }
  let!(:easy_helpdesk_project_matching) { FactoryGirl.create(:to_easy_helpdesk_project_matching, easy_helpdesk_project: easy_helpdesk_project_to_easy) }

  it 'should create an issue' do
    Role.anonymous.add_permission! :add_issues
    issue = submit_email('helpdesk_ticket_basic.eml', :unknown_user => 'accept')
    assert_issue_created issue
    expect(issue.easy_helpdesk_need_reaction).to eq true
    expect(issue.subject).to include 'Test subject'
    expect(issue.description).to include 'Hello'
    expect(issue.author).to eq User.anonymous
    expect(issue.project.easy_helpdesk_project).to eq easy_helpdesk_project_to_easy
  end

  it 'should create an issue invalid encoding' do
    Role.anonymous.add_permission! :add_issues
    issue = submit_email('helpdesk_ticket_with_invalid_encoding.eml', :unknown_user => 'accept')
    assert_issue_created issue
  end

  it 'should create an issue iso-8859-8-i' do
    Role.anonymous.add_permission! :add_issues
    issue = submit_email('helpdesk_ticket_iso-8859-8-i.eml', :unknown_user => 'accept')
    assert_issue_created issue
    expect(issue.subject).to include 'Verification'
    expect(issue.description).to include 'Ok'
  end

  context 'reply email' do
    let(:blank_template) { FactoryBot.build_stubbed(:easy_helpdesk_mail_template) }

    it 'with a blank template' do
      Role.anonymous.add_permission! :add_issues
      allow(EasyHelpdeskMailTemplate).to receive(:find_from_issue).and_return(blank_template)

      expect {
        submit_email('helpdesk_ticket_basic.eml', :unknown_user => 'accept', :easy_helpdesk_mailbox_username => 'support@easy.cz')
      }.to change { ActionMailer::Base.deliveries.size }.by(1)

      with_settings(text_formatting: 'HTML') do
        expect {
          submit_email('helpdesk_ticket_basic.eml', :unknown_user => 'accept', :easy_helpdesk_mailbox_username => 'support@easy.cz')
        }.to change { ActionMailer::Base.deliveries.size }.by(1)
      end
    end
  end

  it 'should create an issue utf7' do
    Role.anonymous.add_permission! :add_issues
    issue = submit_email('helpdesk_ticket_utf7.eml', :unknown_user => 'accept')
    assert_issue_created issue
    expect(issue.description).to include 'Ok'
  end

  it 'coworkers' do
    Role.anonymous.add_permission! :add_issues, :add_issue_watchers
    user = FactoryBot.create(:user, mail: 'dominika@easy.cz')
    FactoryBot.create(:member, project: easy_helpdesk_project_to_easy.project, user: user)
    issue = submit_email('helpdesk_ticket_coworkers.eml', :unknown_user => 'accept')
    assert_issue_created issue
    expect(issue.watcher_user_ids).to include user.id

  end

  it 'coworkers non member' do
    Role.anonymous.add_permission! :add_issues, :add_issue_watchers
    user = FactoryBot.create(:user, mail: 'dominika@easy.cz')
    issue = submit_email('helpdesk_ticket_coworkers.eml', :unknown_user => 'accept')
    assert_issue_created issue
    expect(issue.watcher_user_ids).not_to include user.id
  end

  it 'should create an issue with correct encoding' do
    Role.anonymous.add_permission! :add_issues
    issue = submit_email('helpdesk_ticket_encoding_check.eml', :unknown_user => 'accept')
    assert_issue_created issue
    expect(issue.subject).to include 'Příliš žluťoučký kůň оно работает!'
    expect(issue.description).to include 'Příliš žluťoučký kůň оно работает!'
  end

  it 'should create an issue with correct encoding2' do
    Role.anonymous.add_permission! :add_issues
    issue = submit_email('helpdesk_ticket_encoding_check2.eml', :unknown_user => 'accept')
    assert_issue_created issue
    expect(issue.subject).to include 'Příliš žluťoučký kůň оно работает!'
  end

  it 'should create an issue without a subject' do
    Role.anonymous.add_permission! :add_issues
    issue = submit_email('helpdesk_ticket_without_subject.eml', :unknown_user => 'accept')
    assert_issue_created issue
    expect(issue.description).to include 'Hello'
    expect(issue.author).to eq User.anonymous
    expect(issue.project.easy_helpdesk_project).to eq easy_helpdesk_project_to_easy
  end

  it 'should create an issue with too long id in subject' do
    Role.anonymous.add_permission! :add_issues
    assert_issue_created submit_email('helpdesk_ticket_too_long_id.eml', :unknown_user => 'accept')
  end

  it 'should attach original eml' do
    Role.anonymous.add_permission! :add_issues
    issue = submit_email('helpdesk_ticket_basic.eml', :unknown_user => 'accept')
    assert_issue_created issue
    attachments = issue.attachments.where("filename LIKE '%.eml'")
    expect(attachments.count).to eq 1
    expect(File.zero?(attachments.first.diskfile)).to be false
  end

  it 'should attach original eml test long subject' do
    Role.anonymous.add_permission! :add_issues
    issue = submit_email('helpdesk_ticket_long_subject.eml', :unknown_user => 'accept')
    assert_issue_created issue
    attachments = issue.attachments.where("filename LIKE '%.eml'")
    expect(attachments.count).to eq 1
    expect(File.zero?(attachments.first.diskfile)).to be false
  end

  it 'should update rake task status' do
    task = EasyRakeTaskEasyHelpdeskReceiveMail.create!
    info = task.easy_rake_task_infos.create!(:status => 0, :started_at => Time.now)
    info_detail = info.easy_rake_task_info_details.create!(:type => 'EasyRakeTaskInfoDetailReceiveMail')

    Role.anonymous.add_permission! :add_issues
    issue = false
    expect {
      issue = submit_email('helpdesk_ticket_basic.eml', :unknown_user => 'accept', :easy_rake_task => task, :easy_rake_task_info_detail => info_detail)
    }.not_to raise_exception
    assert_issue_created issue

    expect(info_detail.entity_type).to eq(issue.class.name)
    expect(info_detail.entity_id).to eq(issue.id)
    expect(info_detail.detail).to include('created')
  end

  it 'autoreply' do
    Role.anonymous.add_permission! :add_issues
    expect {
      expect(submit_email('helpdesk_ticket_autoreply.eml', :unknown_user => 'accept')).to eq(EasyMailHandler::STATUS_SUCCESSFUL)
    }.not_to change(Issue, :count)
  end

  context 'issue reply' do
    let(:issue) { FactoryGirl.build(:issue) }
    before(:each) { Role.anonymous.add_permission!(:add_issues, :add_issue_notes) }

    def prepare_issue_reply(issue)
      raw = IO.read(File.join(File.dirname(__FILE__) + '/../../fixtures/easy_helpdesk_mail_handler', 'helpdesk_ticket_reply.eml'))
      raw.sub!('%issue_id%', issue.id.to_s)
      raw
    end

    it 'create journal' do
      issue.save!
      raw = prepare_issue_reply(issue)

      expect{
        EasyHelpdeskMailHandler.receive(raw, :unknown_user => 'accept')
      }.to change(issue.journals, :count).by(1)
      expect(issue.journals.last.notes).to eq('Hello')

      with_settings(text_formatting: 'HTML') do
        expect{
          EasyHelpdeskMailHandler.receive(raw, :unknown_user => 'accept')
        }.to change(issue.journals, :count).by(1)
        expect(issue.journals.last.notes).to eq('<div class="easy_long_note"><div><p>Hello<br></p></div></div>')
      end
    end

    def test_invalid_issue(issue, body, validate = false)
      expect{
        EasyHelpdeskMailHandler.receive(body, :unknown_user => 'accept', :no_issue_validation => !validate)
      }.to change(issue.journals, :count).by(validate ? 0 : 1)
      unless validate
        expect(issue.journals.last.notes).to eq('Hello')
      end

      with_settings(text_formatting: 'HTML') do
        expect{
          EasyHelpdeskMailHandler.receive(body, :unknown_user => 'accept', :no_issue_validation => !validate)
        }.to change(issue.journals, :count).by(validate ? 0 : 1)
        unless validate
          expect(issue.journals.last.notes).to eq('<div class="easy_long_note"><div><p>Hello<br></p></div></div>')
        end
      end
    end

    context 'invalid issue' do
      before(:each) do
        issue.subject = ''
        issue.save(:validate => false)
        expect(issue.reload.valid?).to eq(false)
      end

      it 'with validation' do
        test_invalid_issue(issue, prepare_issue_reply(issue), true)
      end

      it 'without validation' do
        test_invalid_issue(issue, prepare_issue_reply(issue), false)
      end
    end
  end

  context 'domain name' do
    let!(:easy_helpdesk_project_to_easy_mailbox) { FactoryGirl.create(:easy_helpdesk_project) }
    let!(:easy_helpdesk_project_matching_mailbox) { FactoryGirl.create(:to_easy_helpdesk_project_matching, easy_helpdesk_project: easy_helpdesk_project_to_easy_mailbox, domain_name: 'mailbox@easy.cz') }

    it 'should create an issue by domain name' do
      Role.anonymous.add_permission! :add_issues
      issue1 = submit_email('helpdesk_ticket_basic.eml', :unknown_user => 'accept')
      assert_issue_created issue1
      issue2 = submit_email('helpdesk_ticket_to_mailbox.eml', :unknown_user => 'accept')
      assert_issue_created issue2
      expect(issue1.project_id).not_to eq issue2.project_id
      expect(issue1.project_id).to eq easy_helpdesk_project_to_easy.project_id
      expect(issue2.project_id).to eq easy_helpdesk_project_to_easy_mailbox.project_id
    end
  end

  context 'with external email' do
    it 'should fill email to and email cc' do
      Role.anonymous.add_permission! :add_issues
      issue = submit_email('helpdesk_ticket_with_cc.eml', :unknown_user => 'accept')
      assert_issue_created issue
      expect(issue.easy_email_to).to eq 'petr.vesely@easy.cz'
      expect(issue.easy_email_cc).to eq 'jaroslav.vesely@easy.cz, pavel.vesely@easy.cz'
    end

    it 'should fill email to and email cc and reject emission address' do
      Role.anonymous.add_permission! :add_issues
      with_settings(mail_from: 'mailbox@easy.cz') do
        issue = submit_email('helpdesk_ticket_with_emission_and_cc.eml', :unknown_user => 'accept')
        assert_issue_created issue
        expect(issue.easy_email_to).to eq 'petr.vesely@easy.cz'
        expect(issue.easy_email_cc).to eq 'jaroslav.vesely@easy.cz, jerry@easy.cz'
      end
    end
  end

  context 'with prefilled attributes' do

    let(:issue_custom_field) { FactoryGirl.create(:issue_custom_field, :name => 'MyMailCF',
        :trackers => [easy_helpdesk_project_to_easy.tracker_id]) }

    it 'should fill attributes from email' do
      Role.anonymous.add_permission! :add_issues
      Role.anonymous.add_permission! :edit_issues
      Role.anonymous.add_permission! :view_estimated_hours
      issue_custom_field
      options = {:unknown_user => 'accept', :allow_override => EasyHelpdesk.override_attributes.join(',')}
      issue = submit_email('helpdesk_ticket_with_attributes.eml', options)
      assert_issue_created issue
      expect(issue.estimated_hours).to eq 15
      expect(issue.custom_values).to be_present
      cv = issue.custom_values.detect{|i| i.custom_field_id == issue_custom_field.id}
      expect(cv).to be_present
      expect(cv.value).to eq 'VALUE'
    end

    it 'should fill attributes from email html' do
      Role.anonymous.add_permission! :add_issues
      Role.anonymous.add_permission! :edit_issues
      issue_custom_field
      options = {:unknown_user => 'accept', :allow_override => EasyHelpdesk.override_attributes.join(',')}
      with_settings(:text_formatting => 'HTML') do
        issue = submit_email('helpdesk_ticket_with_attributes.eml', options)
        assert_issue_created issue
        expect(issue.custom_values).to be_present
        cv = issue.custom_values.detect{|i| i.custom_field_id == issue_custom_field.id}
        expect(cv).to be_present
        expect(cv.value).to eq 'VALUE'
      end
    end

    it 'should fill a category from email' do
      Role.anonymous.add_permission! :add_issues
      Role.anonymous.add_permission! :edit_issues
      category = FactoryBot.create :issue_category, project: easy_helpdesk_project_to_easy.project, name: 'root category'
      options = {:unknown_user => 'accept', :allow_override => EasyHelpdesk.override_attributes.join(',')}
      issue = submit_email('helpdesk_ticket_with_category.eml', options)
      assert_issue_created issue
      expect(issue.reload.category_id).to eq category.id
    end

    it 'should fill attributes from plaintext email' do
      Role.anonymous.add_permission! :add_issues
      Role.anonymous.add_permission! :edit_issues
      Role.anonymous.add_permission! :view_estimated_hours
      issue_custom_field
      options = {:unknown_user => 'accept', :allow_override => EasyHelpdesk.override_attributes.join(',')}
      issue = submit_email('helpdesk_ticket_with_attributes_plain.eml', options)
      assert_issue_created issue
      expect(issue.estimated_hours).to eq 15
      expect(issue.custom_values).to be_present
      cv = issue.custom_values.detect{|i| i.custom_field_id == issue_custom_field.id}
      expect(cv).to be_present
      expect(cv.value).to eq 'VALUE'
    end

    it 'should create an issue with attributes and unknown encoding' do
      Role.anonymous.add_permission! :add_issues
      Role.anonymous.add_permission! :edit_issues
      Role.anonymous.add_permission! :view_estimated_hours
      options = {:unknown_user => 'accept', :allow_override => EasyHelpdesk.override_attributes.join(',')}
      issue = submit_email('helpdesk_ticket_unknown_encoding.eml', options)
      assert_issue_created issue
      expect(issue.subject).to include 'Test subject'
      expect(issue.description).to include 'Hello'
      expect(issue.author).to eq User.anonymous
      expect(issue.project.easy_helpdesk_project).to eq easy_helpdesk_project_to_easy
      expect(issue.estimated_hours).to eq 15
    end

    it 'should log spent time' do
      Role.anonymous.add_permission! :add_issues
      Role.anonymous.add_permission! :edit_issues
      Role.anonymous.add_permission! :log_time
      FactoryBot.create(:time_entry_activity)
      options = {:unknown_user => 'accept', :allow_override => EasyHelpdesk.override_attributes.join(',')}
      issue = submit_email('helpdesk_ticket_spent_time.eml', options)
      assert_issue_created issue
      expect(issue.spent_hours).to eq 2.5
    end
  end

  it 'should issue created with watchers' do
    Role.anonymous.add_permission! :add_issues
    Role.non_member.add_permission! :add_issues
    Role.anonymous.add_permission! :add_issue_watchers
    Role.non_member.add_permission! :add_issue_watchers

    u1 = FactoryGirl.create(:user, {:mail => 'pavel.vesely@easy.cz'})
    u2 = FactoryGirl.create(:user, {:mail => 'petr.vesely@easy.cz'})
    u3 = FactoryGirl.create(:user, {:mail => 'jaroslav.vesely@easy.cz'})
    easy_helpdesk_project_to_easy.update_attribute(:watchers_ids, [u1.id, u2.id])

    issue = submit_email('helpdesk_ticket_with_cc.eml', :unknown_user => 'accept')
    assert_issue_created issue
  end

  context 'multiple trackers' do
    let!(:tracker) { FactoryBot.create(:tracker, projects: [easy_helpdesk_project_to_easy.project]) }
    let(:issue_custom_field) { FactoryBot.create(:issue_custom_field, name: 'MyMailCF',
        trackers: [tracker]) }

    it 'should prefer helpdesk tracker' do
      Role.anonymous.add_permission! :add_issues
      Role.anonymous.add_permission! :edit_issues
      easy_helpdesk_project_to_easy.update_column(:tracker_id, tracker.id)
      issue_custom_field
      options = {unknown_user: 'accept', allow_override: EasyHelpdesk.override_attributes.join(',')}
      issue = submit_email('helpdesk_ticket_with_attributes.eml', options)
      assert_issue_created issue
      expect(issue.custom_values).to be_present
      cv = issue.custom_values.detect{|i| i.custom_field_id == issue_custom_field.id}
      expect(cv).to be_present
      expect(cv.value).to eq 'VALUE'
    end

    it 'no permission check' do
      Role.anonymous.add_permission! :add_issues
      Role.anonymous.add_permission! :edit_issues
      easy_helpdesk_project_to_easy.update_column(:tracker_id, tracker.id)
      options = {unknown_user: 'accept', allow_override: EasyHelpdesk.override_attributes.join(','), no_permission_check: '1'}
      issue = submit_email('helpdesk_ticket_with_attributes.eml', options)
      assert_issue_created issue
      expect(issue.tracker_id).to eq(tracker.id)
    end
  end

  def submit_ticket_with_image
    issue = submit_email('helpdesk_ticket_with_image.eml', :unknown_user => 'accept')
    assert_issue_created issue
    expect(issue.subject).to include 'Test subject'
    expect(issue.description).to include 'Hello'
    expect(issue.attachments.count).to eq(2)
  end

  it 'image attachment' do
    Role.anonymous.add_permission! :add_issues
    with_easy_settings(:attachment_description_required => false) { submit_ticket_with_image }
    with_easy_settings(:attachment_description_required => true)  { submit_ticket_with_image }
    with_settings(:text_formatting => 'HTML')                     { submit_ticket_with_image }
  end
end
