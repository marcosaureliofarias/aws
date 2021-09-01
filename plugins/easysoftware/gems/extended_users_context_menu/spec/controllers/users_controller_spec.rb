RSpec.describe UsersController, logged: :admin do

  let(:user) { FactoryGirl.create(:user) }

  describe '#add_users_to_group' do
    let(:user1) { FactoryGirl.create(:user) }
    let(:group1) {
      group = FactoryGirl.create(:eucm_group)
      group.users = [user1]
      group
    }
    let(:group2) { FactoryGirl.create(:eucm_group) }

    it 'adds users to group' do
      group1
      expect(user1.group_ids).to eq([group1.id])
      expect(user.group_ids).to be_empty

      put :add_users_to_group, params: { ids: [user1.id, user.id], user: { group_id: group2.id } }

      user1.reload; user.reload
      expect(user1.group_ids).to include(group1.id, group2.id)
      expect(user.group_ids).to eq([group2.id])
    end

  end

  describe '#bulk_calendar_to_user' do
    let(:parent_calendar) { double(EasyUserWorkingTimeCalendar, id: 99) }
    let!(:calendar) { FactoryBot.create(:eucm_easy_user_time_calendar, user: user, parent_id: nil) }

    it do
      allow(EasyUserWorkingTimeCalendar).to receive(:find_by).with(id: '99').and_return(parent_calendar)
      put :bulk_calendar_to_user, params: { ids: [user], calendar_id: '99' }

      expect(calendar.reload.parent_id).to eq(99)
    end
  end

  describe '#bulk_generate_passwords' do
    it 'generates new password and sends it to the user' do
      expect(Mailer).to receive(:deliver_account_information).with(user, anything)

      expect { put :bulk_generate_passwords, params: { ids: [user] } }.to change { user.reload.hashed_password }
    end
  end

  describe '#bulk_next_login_passwords' do
    it do
      expect { put :bulk_next_login_passwords, params: { ids: [user] } }.to change { user.reload.must_change_passwd }.to(true)
    end
  end

  describe '#bulk_update_page_template' do
    let(:page_template) { double(EasyPageTemplate) }

    it do
      allow(EasyPageTemplate).to receive(:find_by).with(id: '66').and_return(page_template)
      expect(EasyPageZoneModule).to receive(:create_from_page_template).with(page_template, user.id)

      put :bulk_update_page_template, params: { ids: [user], page_template_id: '66' }
    end
  end

end
