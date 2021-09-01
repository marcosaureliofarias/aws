require 'easy_extensions/spec_helper'

describe EasyInvitation do

  let(:invitation) { FactoryBot.create(:easy_invitation) }

  it 'is destroyed when user is destroyed' do
    invitation.user.destroy
    expect( EasyInvitation.find_by_id(invitation.id) ).to be_nil
  end

  it 'is destroyed when meeting is destroyed' do
    invitation.easy_meeting.reload.destroy
    expect( EasyInvitation.find_by_id(invitation.id) ).to be_nil
  end

  describe '.visible' do
    let(:easy_user_type_1) { FactoryBot.create(:easy_user_type) }
    let(:easy_user_type_2) { FactoryBot.create(:easy_user_type) }

    let(:author) { FactoryBot.create(:user, easy_user_type: easy_user_type_1) }
    let(:restricted_invitee) { FactoryBot.create(:user, easy_user_type: easy_user_type_2) }
    let(:invitee_2) { FactoryBot.create(:user, easy_user_type: easy_user_type_1) }
    let(:invitee_3) { FactoryBot.create(:user, easy_user_type: easy_user_type_2) }

    let(:invitation_1) { FactoryBot.create(:easy_invitation, easy_meeting: meeting, user: restricted_invitee, accepted: true) }
    let(:invitation_2) { FactoryBot.create(:easy_invitation, easy_meeting: meeting, user: invitee_2, accepted: true) }
    let(:invitation_3) { FactoryBot.create(:easy_invitation, easy_meeting: meeting, user: invitee_3, accepted: true) }


    let(:meeting) { FactoryBot.create(:easy_meeting, author: author) }

    before do
      easy_user_type_1.easy_user_visible_types = [easy_user_type_1, easy_user_type_2]
      easy_user_type_2.easy_user_visible_types = [easy_user_type_2]
    end

    context 'without argument' do
      before do
        allow(User).to receive(:current).and_return current_user
      end

      context 'author' do
        let(:current_user) { author }

        it 'returns own invitation' do
          meeting
          own_invitation = EasyInvitation.where(user: current_user).first

          expect(described_class.visible.ids).to include own_invitation.id
        end
      end

      context 'admin' do
        let(:current_user) { FactoryBot.create(:admin_user) }

        it 'returns all invitations' do
          invitation_1
          invitation_2
          invitation_3

          expect(described_class.visible.size).to eq 4
          expect(described_class.visible.ids).to include invitation_1.id, invitation_2.id, invitation_3.id
        end
      end

      context 'invitee' do
        let(:current_user) { restricted_invitee }

        it 'returns invitations only for users of visible types' do
          invitation_1
          invitation_2
          invitation_3

          expect(described_class.visible.size).to eq 2
          expect(described_class.visible.ids).to include invitation_1.id, invitation_3.id
        end
      end
    end

    context 'with argument' do
      it 'allows user to be passed as an argument' do
        invitation_1
        invitation_2
        invitation_3

        expect(described_class.visible(invitee_2).size).to eq 4
      end
    end
  end

end
