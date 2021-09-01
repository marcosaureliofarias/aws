require_relative '../spec_helper'

describe EasyCrmCase, :logged => :admin do
  let(:easy_contact) {FactoryGirl.create(:easy_contact)}

  let(:easy_crm_case1) { FactoryGirl.create(:easy_crm_case, :with_items, :with_contacts) }
  let(:easy_crm_case2) { FactoryGirl.create(:easy_crm_case, :with_items, :with_contacts) }
  let(:easy_crm_case_status) { FactoryGirl.create(:easy_crm_case_status) }
  let(:easy_crm_case_status_required_contact) { FactoryGirl.create(:easy_crm_case_status, is_easy_contact_required: true) }
  let(:easy_crm_admin_status) { FactoryGirl.create(:easy_crm_case_status, only_for_admin: true) }
  let(:easy_crm_case_with_status_only_admin) { FactoryGirl.create(:easy_crm_case, easy_crm_case_status: easy_crm_admin_status) }
  let(:user) { FactoryGirl.create(:user)}
  let(:project) { FactoryGirl.create(:project, :add_modules => ['easy_crm']) }

  it 'should check validation' do
    expect( FactoryGirl.build(:easy_crm_case, author_id: User.current.id, project: project, easy_crm_case_status: easy_crm_case_status_required_contact).save ).to eq(false)
    expect( FactoryGirl.build(:easy_crm_case, author_id: User.current.id, project: project, easy_crm_case_status: easy_crm_case_status).save ).to eq(true)
    expect( FactoryGirl.build(:easy_crm_case, author_id: User.current.id, project: project, easy_crm_case_status: easy_crm_case_status_required_contact, easy_contact_ids: Array(easy_contact.id), main_easy_contact_id: easy_contact.id).save ).to eq(true)
  end

  it 'should merge journals correctly' do
    easy_crm_case1_journals_count = easy_crm_case1.journals.count
    easy_crm_case2_journals_count = easy_crm_case2.journals.count

    EasyCrmCase.easy_merge_and_close_crms([easy_crm_case1, easy_crm_case2], easy_crm_case1)

    expect( easy_crm_case2.journals.count ).to eq(1 + easy_crm_case2_journals_count)
    expect( easy_crm_case1.journals.count ).to eq(0)
  end

  it 'should merge easy contacts correctly' do
    # duplication of contact
    easy_crm_case1.easy_contacts << easy_crm_case2.easy_contacts.first

    easy_crm_case2_contacts_count = easy_crm_case2.easy_contacts.count

    EasyCrmCase.easy_merge_and_close_crms([easy_crm_case1, easy_crm_case2], easy_crm_case1)

    expect( easy_crm_case2.easy_contacts.count ).to eq(easy_crm_case2_contacts_count)
    expect(easy_crm_case1.easy_contacts).to match_array(easy_crm_case1.easy_contacts.to_a.concat(easy_crm_case2.easy_contacts).uniq)
  end

  it 'workflow required validation' do
    easy_crm_admin_status
    expect( FactoryGirl.build(:easy_crm_case, author_id: User.current.id, project: project, price: nil, easy_crm_case_status: easy_crm_case_status).save ).to eq(true)
    WorkflowCrmPermission.create(old_status_id: easy_crm_case_status.id, field_name: 'price', rule: 'required')
    expect( FactoryGirl.build(:easy_crm_case, author_id: User.current.id, project: project, price: nil, easy_crm_case_status: easy_crm_case_status).save ).to eq(false)
    expect( FactoryGirl.build(:easy_crm_case, author_id: User.current.id, project: project, price: 10, easy_crm_case_status: easy_crm_case_status).save ).to eq(true)
    expect( FactoryGirl.build(:easy_crm_case, author_id: User.current.id, project: project, price: nil, easy_crm_case_status: easy_crm_admin_status).save ).to eq(true)
  end

  it 'Admin change status only admin' do
    expect(easy_crm_case1.easy_crm_case_status.only_for_admin).to be_falsey
    easy_crm_case1.easy_crm_case_status = easy_crm_admin_status
    expect(easy_crm_case1.save).to be_truthy
  end

  it 'NONAdmin change status only admin', logged: true do
    expect(User.current.admin).to be_falsey
    expect(easy_crm_case1.easy_crm_case_status.only_for_admin).to be_falsey
    easy_crm_case1.easy_crm_case_status = easy_crm_admin_status
    expect(easy_crm_case1.save).to be_falsey
  end

  it 'NONAdmin change attribute under status only admin' do
    expect(easy_crm_case_with_status_only_admin.easy_crm_case_status.only_for_admin).to be_truthy
    logged_user(user)
    expect(User.current.admin).to be_falsey
    easy_crm_case_with_status_only_admin.price = 555
    expect(easy_crm_case_with_status_only_admin.save).to be_truthy
  end

  context 'issue_related_contact' do
    let(:easy_crm_case) { FactoryBot.create(:easy_crm_case, easy_contacts: [easy_contact1, easy_contact3]) }
    let(:issue) { FactoryBot.create(:issue, easy_contacts: [easy_contact1, easy_contact2]) }
    let(:easy_contact1) { FactoryBot.create(:easy_contact) }
    let(:easy_contact2) { FactoryBot.create(:easy_contact) }
    let(:easy_contact3) { FactoryBot.create(:easy_contact) }

    it 'add issue with duplicated contacts' do
      easy_crm_case.issues << issue
      expect(easy_crm_case.reload.easy_contact_ids).to match_array([easy_contact1.id, easy_contact3.id])
      expect(issue.reload.easy_contact_ids).to match_array([easy_contact1.id, easy_contact2.id, easy_contact3.id])
    end
  end

  context 'custom values' do
    let!(:easy_crm_status) { FactoryGirl.create(:easy_crm_case_status) }
    let(:easy_crm_case) { FactoryGirl.create(:easy_crm_case, :with_custom_fields) }

    it 'reassign' do
      original_status_id = easy_crm_case.easy_crm_case_status.id
      expect(easy_crm_case.editable_custom_field_values.count).to eq(2)
      easy_crm_case.safe_attributes = {'easy_crm_case_status_id' => easy_crm_status.id.to_s}
      expect(easy_crm_case.editable_custom_field_values.count).to eq(0)
      easy_crm_case.safe_attributes = {'easy_crm_case_status_id' => original_status_id.to_s}
      expect(easy_crm_case.editable_custom_field_values.count).to eq(2)
    end
  end

  let(:easy_crm_case_status_required_contact) { FactoryGirl.create(:easy_crm_case_status, is_easy_contact_required: true)}
  let(:easy_crm_case_without_main_easy_contact) { FactoryGirl.build(:easy_crm_case, author_id: User.current.id, project: project, main_easy_contact: nil, easy_crm_case_status: easy_crm_case_status_required_contact) }

  it 'crm with required contact' do
    easy_crm_case_without_main_easy_contact
    expect(easy_crm_case_without_main_easy_contact).not_to be_valid
    easy_crm_case_without_main_easy_contact.main_easy_contact_id = easy_contact.id
    expect(easy_crm_case_without_main_easy_contact).to be_valid
  end

  context 'watchers' do
    let(:group) { FactoryGirl.create(:group, :users => [user]) }
    let(:project) { FactoryGirl.create(:project, :add_modules => ['easy_crm']) }

    it 'user' do
      crm = EasyCrmCase.new
      crm.safe_attributes = {'watcher_user_ids' => [user.id], 'name' => 'test', 'project_id' => project.id, 'author_id' => User.current.id, 'easy_crm_case_status_id' => easy_crm_case_status.id}
      expect(crm.watcher_user_ids).to eq([user.id])
    end

    it 'group' do
      crm = EasyCrmCase.new
      crm.safe_attributes = {'watcher_group_ids' => [group.id], 'name' => 'test', 'project_id' => project.id, 'author_id' => User.current.id, 'easy_crm_case_status_id' => easy_crm_case_status.id}
      expect(crm.watcher_group_ids).to eq([group.id])
    end
  end

  it 'previous external assignee' do
    crm = easy_crm_case1
    crm.safe_attributes = {'external_assigned_to_id' => user.id.to_s}
    crm.save
    expect(crm.previous_external_assignee).to eq(nil)
    crm.reload
    crm.safe_attributes = {'external_assigned_to_id' => User.current.id.to_s}
    crm.save
    expect(crm.previous_external_assignee).to eq(user)
  end

  describe 'recalculate main contact' do
    let(:easy_crm_case) { FactoryGirl.create(:easy_crm_case) }

    it 'recalculate is job enqueued' do
      expect {
        easy_crm_case.update(main_easy_contact: easy_contact)
      }.to have_enqueued_job(EasyCrm::RecalculateEasyContactFields)
    end if Redmine::Plugin.installed?(:easy_computed_custom_fields)

  end

end
