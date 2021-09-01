require 'easy_extensions/spec_helper'

describe EasyIssuesController, logged: :admin do

  let(:issue) { FactoryGirl.create(:issue) }

  describe 'form fields' do
    render_views

    it 'get' do
      get :form_fields, params: { id: issue.id, project_id: issue.project.id, format: 'json' }
      expect(response).to be_successful

      get :form_fields, params: { project_id: issue.project.id, format: 'json' }
      expect(response).to be_successful

      get :form_fields, params: { id: Issue.last.id + 1, project_id: issue.project.id, format: 'json' }
      expect(response).to have_http_status(404)

      issue.project.trackers = []
      get :form_fields, params: { project_id: issue.project.id, format: 'json' }
      expect(response).to have_http_status(500)
    end
  end

  describe 'remove_child' do
    let(:child_issue) { FactoryGirl.create(:issue, :child_issue) }

    it 'admin' do
      delete :remove_child, params: { id: child_issue.parent_id, child_id: child_issue.id }
      expect(child_issue.reload.parent_id).to eq(nil)
    end

    it 'regular with permissions', logged: true do
      role = Role.non_member
      role.add_permission! :manage_subtasks, :edit_issues
      delete :remove_child, params: { id: child_issue.parent_id, child_id: child_issue.id }
      expect(child_issue.reload.parent_id).to eq(nil)
    end

    it 'regular', logged: true do
      delete :remove_child, params: { id: child_issue.parent_id, child_id: child_issue.id }
      expect(response).to have_http_status(403)
      expect(child_issue.reload.parent_id).not_to eq(nil)
    end
  end

  describe 'issue tabs' do
    render_views

    let(:time_entry) { FactoryGirl.create(:time_entry, issue: issue) }

    it 'render spent_time' do
      time_entry
      get :render_tab, params: { tab: 'spent_time', id: issue.id }
      expect(response).to be_successful
    end

    it 'render easy_entity_activity' do
      get :render_tab, params: { tab: 'easy_entity_activity', id: issue.id }
      expect(response).to be_successful
    end
  end

end
