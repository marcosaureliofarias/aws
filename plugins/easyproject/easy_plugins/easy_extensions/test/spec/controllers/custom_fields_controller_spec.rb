require 'easy_extensions/spec_helper'

describe CustomFieldsController, logged: :admin do

  let(:issue_custom_field) { FactoryGirl.create(:issue_custom_field, :easy_group_id => nil) }

  render_views

  context 'update form' do
    it 'edit' do
      post :update_form, :params => { :id => issue_custom_field.id, :custom_field => { :name => 'test name' }, :format => 'js' }
      expect(response).to be_successful
      expect(response.body).to include('test name')
    end

    it 'new' do
      post :update_form, :params => { :type => 'IssueCustomField', :custom_field => { :name => 'test name' }, :format => 'js' }
      expect(response).to be_successful
      expect(response.body).to include('test name')
    end
  end

  context 'groups' do
    let(:easy_group) { FactoryGirl.create(:easy_custom_field_group) }

    it 'new group on create' do
      put :create, :params => { :type => 'IssueCustomField', :custom_field => { :name => 'test name', :easy_group_id => 'New group', :field_format => 'string' } }
      expect(EasyCustomFieldGroup.find_by(:name => 'New group')).not_to eq(nil)
    end

    it 'assign group on create' do
      easy_group
      expect {
        put :create, :params => { :type => 'IssueCustomField', :custom_field => { :name => 'test name', :easy_group_id => easy_group.id.to_s, :field_format => 'string' } }
      }.to change(EasyCustomFieldGroup, :count).by(0)
      expect(CustomField.where(:easy_group_id => easy_group.id).count).to eq(1)
    end

    it 'new group on update' do
      post :update, :params => { :id => issue_custom_field, :custom_field => { :easy_group_id => 'New group' } }
      group = EasyCustomFieldGroup.find_by(:name => 'New group')
      expect(group).not_to eq(nil)
      expect(issue_custom_field.reload.easy_group_id).to eq(group.id)
    end

    it 'assign group on update' do
      easy_group
      expect {
        post :update, :params => { :id => issue_custom_field, :custom_field => { :easy_group_id => easy_group.id.to_s } }
      }.to change(EasyCustomFieldGroup, :count).by(0)
      expect(CustomField.where(:easy_group_id => easy_group.id).count).to eq(1)
      expect(issue_custom_field.reload.easy_group_id).to eq(easy_group.id)
    end
  end

  context 'groups' do
    let(:easy_group) { FactoryGirl.create(:easy_custom_field_group) }

    it 'new group on create' do
      put :create, :params => { :type => 'IssueCustomField', :custom_field => { :name => 'test name', :easy_group_id => 'New group', :field_format => 'string' } }
      expect(EasyCustomFieldGroup.find_by(:name => 'New group')).not_to eq(nil)
    end

    it 'assign group on create' do
      easy_group
      expect {
        put :create, :params => { :type => 'IssueCustomField', :custom_field => { :name => 'test name', :easy_group_id => easy_group.id.to_s, :field_format => 'string' } }
      }.to change(EasyCustomFieldGroup, :count).by(0)
      expect(CustomField.where(:easy_group_id => easy_group.id).count).to eq(1)
    end

    it 'new group on update' do
      post :update, :params => { :id => issue_custom_field, :custom_field => { :easy_group_id => 'New group' } }
      group = EasyCustomFieldGroup.find_by(:name => 'New group')
      expect(group).not_to eq(nil)
      expect(issue_custom_field.reload.easy_group_id).to eq(group.id)
    end

    it 'assign group on update' do
      easy_group
      expect {
        post :update, :params => { :id => issue_custom_field, :custom_field => { :easy_group_id => easy_group.id.to_s } }
      }.to change(EasyCustomFieldGroup, :count).by(0)
      expect(CustomField.where(:easy_group_id => easy_group.id).count).to eq(1)
      expect(issue_custom_field.reload.easy_group_id).to eq(easy_group.id)
    end
  end

  context 'edit long text' do
    let(:issue) { FactoryBot.create(:issue) }
    let(:issue_custom_field) { FactoryBot.create(:issue_custom_field, easy_group_id: nil, text_formatting: 'full', is_for_all: true, trackers: [issue.tracker]) }

    before(:each) do
      issue.custom_field_values = { issue_custom_field.id.to_s => 'xxx' }
      issue.save
      issue.reload
      get :edit_long_text, params: { id: issue_custom_field.id, customized_class: 'Issue', customized_id: issue.id, url: '/', format: 'js' }, xhr: true
    end

    it 'admin' do
      expect(response).to be_successful
    end

    it 'regular', logged: true do
      expect(response).to be_forbidden
    end
  end

end
