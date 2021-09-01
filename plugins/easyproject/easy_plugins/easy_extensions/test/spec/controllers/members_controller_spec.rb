require 'easy_extensions/spec_helper'

describe MembersController, logged: :admin do
  describe 'POST create' do
    include_context 'members_support'
    context 'roles selected' do
      it 'assigns correct roles on a project' do
        post :create, params: { project_id: project.id, membership: { user_ids: [user.id], role_ids: [role_1.id, role_2.id] } }, xhr: true
        role_ids = user.memberships.where(project_id: project.id).first.roles.map(&:id)
        expect(role_ids).to match_array [role_1.id, role_2.id]
      end

      it 'should not fail when no users selected' do
        post :create, params: { project_id: project.id, membership: { role_ids: [role_1.id, role_2.id] } }, xhr: true
        expect(response.status).to eq(200)
      end

      it 'assigns group members' do
        params = { project_id: project.id, membership: { user_ids: [group.id], role_ids: [role_1.id] } }
        expect {
          post :create, params: params, xhr: true
        }.to change(Member, :count).by(3) # group + 2 users
      end

      it 'assigns group and user members' do
        params = { project_id: project.id, membership: { user_ids: [group.id, user.id], role_ids: [role_1.id] } }
        expect {
          post :create, params: params, xhr: true
        }.to change(Member, :count).by(3) # group + 2 users
      end
    end

    context 'no roles selected => use default roles' do
      it 'assigns default role on a project' do
        post :create, params: { project_id: project.id, membership: { user_ids: [user.id] } }, xhr: true
        role_ids = user.memberships.where(project_id: project.id).first.roles.map(&:id)
        expect(role_ids).to match_array [default_role.id]
      end

      it 'should not fail when no users selected' do
        post :create, params: { project_id: project.id, membership: {} }, xhr: true
        expect(response.status).to eq(200)
      end
    end
  end

  describe "DELETE destroy" do
    render_views
    include_context 'members_support' do
      before do
        allow(Member).to receive(:find).and_return(member)
        allow(member).to receive(:deletable?) { true }
      end
    end
    context 'js request' do
      it 'should not be destroyed if not deletable' do
        allow(member).to receive(:deletable?) { false }
        delete :destroy, params: { id: member.id }, format: :js
        expect(response).to have_http_status(422)
        expect(member.destroyed?).to be_falsey
      end

      it 'should be destroyed if without assigned tasks' do
        allow(member).to receive_message_chain(:assigned_tasks, :exists?) { false }
        delete :destroy, params: { id: member.id }, format: :js
        expect(response).to render_template('destroy')
        expect(member.destroyed?).to be_truthy
      end

      context 'has assigned_tasks' do
        before { issue }
        it 'should not be destroyed if no options passed' do
          delete :destroy, params: { id: member.id }, format: :js
          expect(response).to render_template('members/_form_destroy_notice')
          expect(member.destroyed?).to be_falsey
        end

        it 'tasks should be assigned to nobody if :unassign' do
          delete :destroy, params: { id: member.id, after_destroy: { action: :unassign } }, format: :js
          expect(response).to render_template('destroy')
          expect(member.destroyed?).to be_truthy
          expect(issue.reload.assigned_to_id).to eq(nil)
        end

        it 'tasks should be assigned to user_id if :assign' do
          delete :destroy, params: { id: member.id, after_destroy: { action: :assign, assigned_to_id: User.current.id } }, format: :js
          expect(response).to render_template('destroy')
          expect(member.destroyed?).to be_truthy
          expect(issue.reload.assigned_to_id).to eq(User.current.id)
        end
      end
    end

    context 'api request' do
      it 'should not be destroyed if not deletable' do
        allow(member).to receive(:deletable?) { false }
        delete :destroy, params: { id: member.id }, format: :json
        expect(response).to have_http_status(422)
        expect(member.destroyed?).to be_falsey
      end

      it 'should be destroyed if without assigned tasks' do
        allow(member).to receive_message_chain(:assigned_tasks, :exists?) { false }
        delete :destroy, params: { id: member.id }, format: :json
        expect(response).to have_http_status(:no_content)
        expect(member.destroyed?).to be_truthy
      end

      context 'has assigned_tasks' do
        before { issue }
        it 'should not be destroyed if no options passed' do
          delete :destroy, params: { id: member.id }, format: :json
          expect(response).to render_template('common/error_messages.api')
          expect(response).to have_http_status(422)
          expect(member.destroyed?).to be_falsey
        end

        it 'tasks should be assigned to nobody if :unassign' do
          delete :destroy, params: { id: member.id, after_destroy: { action: :unassign } }, format: :json
          expect(response).to have_http_status(:no_content)
          expect(member.destroyed?).to be_truthy
          expect(issue.reload.assigned_to_id).to eq(nil)
        end

        it 'tasks should be assigned to user_id if :assign' do
          delete :destroy, params: { id: member.id, after_destroy: { action: :assign, assigned_to_id: User.current.id } }, format: :json
          expect(response).to have_http_status(:no_content)
          expect(member.destroyed?).to be_truthy
          expect(issue.reload.assigned_to_id).to eq(User.current.id)
        end
      end
    end
  end
end
