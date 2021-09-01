require 'easy_extensions/spec_helper'

describe IssuesController, logged: :admin do

  render_views

  let!(:project) { FactoryGirl.create(:project, add_modules: ['easy_scrum_board', 'easy_kanban_board']) }
  let!(:sprints) { FactoryGirl.create_list(:easy_sprint, 2, project: project ) }
  let(:issue) { FactoryBot.create(:issue, project: project) }

  describe 'new issue' do
    it 'should not create new issue after refresh' do
      expect{ get :new, params: {project_id: project.id, issue: { subject: 'sprint_issue', tracker_id: project.trackers.first.id, easy_sprint_id: sprints.first.id }} }.to change(Issue, :count).by(0)
      assert_response :success
      expect{ get :new, params: {project_id: project.id, issue: { subject: 'sprint_issue2' }} }.to change(Issue, :count).by(0)
      assert_response :success
      expect{ get :new, params: {project_id: project.id, issue: { easy_sprint_id: sprints.last.id }} }.to change(Issue, :count).by(0)
      assert_response :success
    end
  end

  describe 'create issue' do
    it 'should create new issue with sprint' do
      expect{ post :create, params: {project_id: project.id,
         issue: { subject: 'spent_issue3', tracker_id: project.trackers.first.id, easy_sprint_id: sprints.first.id }} }.
         to change(Issue, :count).by(1)
      expect(Issue.last.easy_sprint).to eq(sprints.first)
    end
  end

  describe 'edit bulk' do
    it 'should has story points field' do
      get :bulk_edit, params: { project_id: project.id, ids: [issue.id] }
      expect(response.body).to have_selector("input[name='issue[easy_story_points]']")
    end
  end

end
