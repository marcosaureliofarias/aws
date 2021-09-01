require 'easy_extensions/spec_helper'

describe ContextMenusController do
  context 'when issue context menu' do
    render_views

    let(:issue) { FactoryGirl.create(:issue) }
    let(:role) do
      role = FactoryGirl.create(:role)
      role.remove_permission!(:edit_issues, :add_issues)
      role
    end
    let(:member) { FactoryGirl.create(:member, :without_roles, :project => issue.project, :user => User.current) }
    let!(:member_role) { FactoryGirl.create(:member_role, :member => member, :role => role) }

    before(:each) { get :issues, :params => { :ids => [issue.id] } }

    context 'when user cannot edit issue', :logged => true do
      it 'does not contain link to update Tracker' do
        expect(response.body).not_to include('tracker_id')
      end
    end

    context 'when user can edit issue', :logged => :admin do
      it 'contains link to update Tracker' do
        expect(response.body).to include('tracker_id')
      end
    end
  end

  context 'time entry context menu', :logged => :admin do
    render_views

    let!(:time_entry) { FactoryGirl.create(:time_entry) }

    it 'removed time entry' do
      time_entry_id = time_entry.id
      time_entry.destroy
      get :time_entries, :params => { :ids => [time_entry_id] }
      expect(response).to have_http_status(404)
    end

    it 'show menu' do
      get :time_entries, :params => { :ids => [time_entry.id] }
      expect(response).to be_successful
    end
  end

  context 'when projects context menu' do
    render_views

    let(:project) { FactoryBot.create(:project) }
    let(:project2) { FactoryBot.create(:project) }
    let(:role) do
      role = Role.non_member
      role.remove_permission!(:select_project_modules)
      role
    end
    before(:each) { get :projects, :params => { ids: [project.id, project2.id] } }

    context 'when user can select modules', :logged => :admin do
      it { expect(response.body).to include(I18n.t(:label_module_manage)) }
    end

    context 'when user cannot select modules', :logged => true do
      it { expect(response.body).not_to include(I18n.t(:label_module_manage)) }
    end
  end

  context 'when attachments context menu', logged: :admin do
    render_views

    let(:issue) { FactoryBot.create(:issue) }
    let(:wiki_page) { FactoryBot.create(:wiki_page) }
    let(:attachment) { FactoryBot.create(:attachment, filename: 'test.png', container: issue) }
    let(:wiki_attachment) { FactoryBot.create(:attachment, filename: 'test.png', container: wiki_page) }

    it 'on issue' do
      get :versioned_attachments, params: { ids: [attachment.id] }
      expect(response).to be_successful
    end

    it 'on wiki' do
      get :versioned_attachments, params: { ids: [wiki_attachment.id] }
      expect(response).to be_successful
    end
  end
end
