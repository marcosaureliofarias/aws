require 'easy_extensions/spec_helper'

describe Journal do

  describe 'notified users of issue journal' do
    let!(:project) { FactoryGirl.create(:project, enabled_module_names: ['issue_tracking'], members: group.users + [parent_assignee]) }
    let(:parent_assignee) { FactoryGirl.create(:user) }
    let(:users) { FactoryGirl.create_list(:user, 2) }
    let(:group) { FactoryGirl.create(:group, users: users) }
    let(:parent_issue) { FactoryGirl.create(:issue, project: project, assigned_to: parent_assignee) }
    let(:issue1) { FactoryGirl.create(:issue, project: project, parent: parent_issue, assigned_to: nil) }
    let(:issue2) { FactoryGirl.create(:issue, project: project, parent: parent_issue, assigned_to: group) }
    let(:issue3) { FactoryGirl.create(:issue, project: project, assigned_to: group.users.first) }
    let(:journal) { FactoryGirl.create(:journal, journalized_id: parent_issue.id, journalized_type: 'Issue', notify_children: true) }
    let(:journal2) { FactoryGirl.create(:journal, journalized_id: issue3.id, journalized_type: 'Issue') }
    let(:detail2) { FactoryGirl.create(:journal_detail, journal: journal2, property: 'attr', prop_key: 'assigned_to_id', old_value: group.id, value: group.users.first.id) }

    it 'returns array of users including users from child issues' do
      issue1; issue2
      assignee_ids = (group.users + [parent_assignee]).map(&:id)
      expect(journal.notified_users.map(&:id)).to match_array(assignee_ids)
    end

    it 'returns array of users including previous assignees' do
      detail2
      expect(journal2.reload.notified_users).to match_array(group.users)
    end
  end

  describe '#send_mentions_notification', logged: true do

    let(:user) { FactoryBot.create(:user) }
    let(:notes) { "User @#{User.current.login} made a bad merge request. @#{user.login} reverted it" }
    subject { FactoryBot.create(:journal, notes: nil, user: user) }

    it 'with mentions and notes' do
      subject.notes = notes
      expect(subject).to receive(:find_mentions).and_return([User.current, user])
      subject.send_mentions_notification
    end

    it 'without notes' do
      expect(subject).to receive(:find_mentions).and_return([])
      subject.send_mentions_notification
    end

  end

  describe 'distributed tasks' do

    let(:source_issue) { FactoryBot.create(:issue) }
    let(:target_issue) { FactoryBot.create(:issue) }
    let(:journal) { FactoryBot.create(:journal, journalized: source_issue) }
    let(:journal_details) { FactoryBot.create_list(:journal_detail, 3, journal: journal) }

    it '#copy_to_issue' do
      journal.copy_to_issue(target_issue)
      copied_journal = target_issue.journals.first
      expect(copied_journal.notes).to eq(journal.notes)
      expect(copied_journal.details).to eq(journal.details)
    end

  end

  describe '#notify_visible_details' do

    let(:custom_field) { FactoryBot.create(:issue_custom_field, mail_notification: 'false') }
    let(:journal) { FactoryBot.create(:journal) }
    let!(:cf_journal_detail) { FactoryBot.create(:journal_detail, journal: journal, property: 'cf', prop_key: custom_field.id) }

    it 'difference notify_visible_details and visible_details' do
      expect(journal.notify_visible_details).to eq([])
      expect(journal.visible_details).to eq([cf_journal_detail])
    end

  end

end
