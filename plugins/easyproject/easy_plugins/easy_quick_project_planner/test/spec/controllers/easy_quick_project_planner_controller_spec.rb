require 'easy_extensions/spec_helper'

describe EasyQuickProjectPlannerController, :logged => :admin do
  render_views

  describe 'POST new_issue_row' do
    let(:project) { FactoryGirl.create(:project, :add_modules => ['quick_planner']) }

    context 'when last available tracker is selected' do
      it 'last tracker is selected' do
        post :new_issue_row, :params => {:id => project.id, :issue => { :tracker_id => project.available_trackers.last.id }}, :xhr => true

        expect(assigns(:issue).tracker).to eq(project.available_trackers.last)
      end
    end

    context 'when no tracker is selected' do
      it 'first available tracker is selected' do
        post :new_issue_row, :params => {:id => project.id}, :xhr => true

        expect(assigns(:issue).tracker).to eq(project.available_trackers.first)
      end
    end
  end
end
