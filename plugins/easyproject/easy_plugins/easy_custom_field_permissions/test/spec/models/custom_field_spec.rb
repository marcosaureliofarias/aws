require_relative '../spec_helper'

describe CustomField, logged: true do

  let(:easy_user_type) { FactoryGirl.create(:easy_user_type) }
  let(:easy_user_type2) { FactoryGirl.create(:easy_user_type) }
  let(:user) { FactoryGirl.create(:user, easy_user_type: easy_user_type) }
  let(:user2) { FactoryGirl.create(:user, easy_user_type: easy_user_type2) }
  let(:group) { FactoryGirl.create(:group, users: [user]) }
  let(:group2) { FactoryGirl.create(:group, users: [user2]) }
  let(:custom_field) { FactoryGirl.create(:issue_custom_field, special_visibility: '1') }

  context 'custom fields availability' do

    it 'blank permissions' do
      expect(custom_field.permitted_custom_field?(user)).to be_falsey
    end

    context 'user' do
      let(:custom_field_not_permitted) { FactoryGirl.create(:issue_custom_field, special_visibility: '1', allowed_user_ids: [user2.id]) }
      let(:custom_field_permitted) { FactoryGirl.create(:issue_custom_field, special_visibility: '1', allowed_user_ids: [user2.id, user.id]) }

      it 'not permitted' do
        expect(custom_field_not_permitted.permitted_custom_field?(user)).to be_falsey
      end

      it 'permitted' do
        expect(custom_field_permitted.permitted_custom_field?(user)).to be
      end

    end

    context 'group' do
      let(:custom_field_not_permitted) { FactoryGirl.create(:issue_custom_field, special_visibility: '1', allowed_group_ids: [group2.id]) }
      let(:custom_field_permitted) { FactoryGirl.create(:issue_custom_field, special_visibility: '1', allowed_group_ids: [group2.id, group.id]) }

      it 'not permitted' do
        expect(custom_field_not_permitted.permitted_custom_field?(user)).to be_falsey
      end

      it 'permitted' do
        expect(custom_field_permitted.permitted_custom_field?(user)).to be
      end

    end

    context 'easy user type' do
      let(:custom_field_not_permitted) { FactoryGirl.create(:issue_custom_field, special_visibility: '1', allowed_easy_user_type_ids: [easy_user_type2.id]) }
      let(:custom_field_permitted) { FactoryGirl.create(:issue_custom_field, special_visibility: '1', allowed_easy_user_type_ids: [easy_user_type2.id, easy_user_type.id]) }

      it 'not permitted' do
        expect(custom_field_not_permitted.permitted_custom_field?(user)).to be_falsey
      end

      it 'permitted' do
        expect(custom_field_permitted.permitted_custom_field?(user)).to be
      end

    end


  end

end
