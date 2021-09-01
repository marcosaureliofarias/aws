require 'easy_extensions/spec_helper'

describe EasySprintsController do

  render_views

  let(:project) { FactoryGirl.create(:project, add_modules: %w(easy_scrum_board easy_kanban_board)) }
  let(:sprint) { FactoryGirl.create(:easy_sprint) }
  let(:sprints) { FactoryGirl.create_list(:easy_sprint, 3, project: project ) }
  let(:sprint_with_issues) { FactoryGirl.create(:easy_sprint, issues: FactoryGirl.create_list(:issue, 3)) }
  let(:past_sprints) { FactoryGirl.create_list(:easy_sprint, 3, project: project, future: false ) }
  let(:issue)  { FactoryGirl.create(:issue) }

  context 'with anonymous user' do
  end

  context 'with admin user', logged: :admin do

    describe 'GET new' do
      # it 'renders 200 for standard requests' do
      #   get :new, :project_id => project.id
      #   expect(response).to be_successful
      # end
      # it 'renders form for XHR requests' do
      #   xhr :get, :new, :project_id => project.id
      #   expect(response).to be_successful
      # end
    end

    describe 'POST create (xhr)' do
      # it 'creates a sprint' do
      #   sprint_attrs = FactoryGirl.attributes_for(:easy_sprint)
      #   expect {xhr :post, :create, project_id: project.id, easy_sprint: sprint_attrs}.to change(EasySprint, :count).by(1)
      #
      #   sprint = EasySprint.last
      #   expect(sprint.project).to eq project
      #   expect(sprint.start_date).to eq sprint_attrs[:start_date]
      #   expect(sprint.due_date).to eq sprint_attrs[:due_date]
      # end

      # it 'renders validation errors if attributes are not valid' do
      #   expect {xhr :post, :create, project_id: project.id, easy_sprint: {:start_date => Date.today}}.not_to change(EasySprint, :count)
      #
      #   expect(response.status).to eq 200
      # end

      # it 'move tasks' do
      #   sprint_attrs = FactoryGirl.attributes_for(:easy_sprint)
      #   old_sprint_id = sprint_with_issues.id
      #
      #   old_related_issue_ids = IssueEasySprintRelation.where(:easy_sprint_id => old_sprint_id).pluck(:issue_id)
      #   old_sprint_ids = Issue.where(:id => old_related_issue_ids).pluck(:easy_sprint_id).uniq
      #   expect(old_related_issue_ids).not_to be_empty
      #   expect(old_sprint_ids).not_to be_empty
      #
      #   all_relations = IssueEasySprintRelation::TYPES.values.map{|type| {relation_type: type, relation_position: ''}}
      #   expect {xhr :post, :create, project_id: project.id, easy_sprint: sprint_attrs, move_task: 'selected', selected_sprint_id: old_sprint_id, sprint_relations: all_relations}.to change(EasySprint, :count).by(1)
      #
      #   old_related_issue_ids2 = IssueEasySprintRelation.where(:easy_sprint_id => old_sprint_id).pluck(:issue_id)
      #   old_sprint_ids2 = Issue.where(:id => old_related_issue_ids2).pluck(:easy_sprint_id).uniq
      #   expect(old_related_issue_ids2).to be_empty
      #   expect(old_sprint_ids2).to be_empty
      #
      #   new_sprint_id = EasySprint.last.id
      #   new_related_issue_ids = IssueEasySprintRelation.where(:easy_sprint_id => new_sprint_id).pluck(:issue_id)
      #   new_sprint_ids = Issue.where(:id => new_related_issue_ids).pluck(:easy_sprint_id).uniq
      #   expect(old_related_issue_ids).to match(new_related_issue_ids)
      #   expect(old_sprint_ids).not_to match(new_sprint_ids)
      #   expect(new_sprint_ids).to match([new_sprint_id])
      # end
    end

    describe 'GET edit (xhr)' do
      # it 'renders sprint form in modal window' do
      #   xhr :get, :edit, project_id: sprint.project_id, id: sprint.id
      #
      #   expect(response.status).to eq 200
      # end
    end

    describe 'PUT update (xhr)' do
      # it 'updates the sprint' do
      #   xhr :put, :update, project_id: sprint.project_id, id: sprint.id, easy_sprint: {name: 'New name'}
      #   assert_response :success
      #   sprint.reload
      #   expect(sprint.name).to eq 'New name'
      # end

      # it 'renders validation errors if params are invalid' do
      #   xhr :put, :update, project_id: sprint.project_id, id: sprint.id, easy_sprint: {name: ''}
      #
      #   expect(response.status).to eq 200
      # end
    end

    describe 'DELETE destroy (xhr)' do
      # it 'destroys the sprint' do
      #   sprint
      #   expect { xhr :delete, :destroy, project_id: sprint.project_id, id: sprint.id }.to change {EasySprint.count}.by(-1)
      # end

      # it 'destroys relations' do
      #   relation_ids = sprint_with_issues.issue_easy_sprint_relations.pluck(:id)
      #   sprint_issue_ids = sprint_with_issues.issue_ids
      #   expect(relation_ids).not_to be_empty
      #   expect { xhr :delete, :destroy, project_id: sprint_with_issues.project_id, id: sprint_with_issues.id }.to change {EasySprint.count}.by(-1)
      #   expect(IssueEasySprintRelation.where(:id => relation_ids)).to be_empty
      #   sprint_issues = Issue.where(:id => sprint_issue_ids)
      #   expect(sprint_issues).not_to be_empty
      #   expect(sprint_issues.pluck(:easy_sprint_id).uniq).to eq [nil]
      # end
    end

    describe 'POST assign_issue' do
      # it 'assigns the issue to a sprint' do
      #   xhr :post, :assign_issue, project_id: sprint.project_id, id: sprint.id, issue_id: issue.id
      #   assert_response :success
      #   EasySprint.last.issue_ids == [Issue.last.id]
      # end

      # it 'adds to issue one journal with just one detail about easy_sprint' do
      #   expect {
      #     xhr :post, :assign_issue, project_id: sprint.project_id, id: sprint.id, issue_id: issue.id, relation_type: IssueEasySprintRelation::TYPE_BACKLOG
      #   }.to change(issue.journals, :count).by(1)
      #
      #   issue.reload
      #   issue_easy_sprint_journal_details = issue.journals.last.details.where(prop_key: :easy_sprint_id)
      #   expect(issue_easy_sprint_journal_details.count).to eq(1)
      # end
    end

    describe 'POST unassign_issue' do
      let(:issue) { FactoryGirl.create(:issue, easy_sprint_id: sprint.id) }

      # it 'adds one journal to issue' do
      #   expect {
      #     xhr :post, :unassign_issue, project_id: sprint.project_id, issue_id: issue.id
      #     }.to change(issue.journals, :count).by(1)
      # end
    end

    describe 'POST reorder' do
      let(:priority) { FactoryGirl.create(:issue_priority, position: 2) }
      let(:issue1) { FactoryGirl.create(:issue, easy_sprint_id: sprint_with_issues.id, priority: priority) }

      it 'reorders issues by priority' do
        issue1
        expect(sprint_with_issues.reload.issue_easy_sprint_relations.order(:position).first.issue_id).not_to eq(issue1.id)
        post :reorder, :params => {format: :json, phase: '-1', issue_ids: sprint_with_issues.issues.pluck(:id), project_id: sprint_with_issues.project_id, id: sprint_with_issues.id}
        assert_response :success
        expect(sprint_with_issues.issue_easy_sprint_relations.order(:position).first.issue_id).to eq(issue1.id)
      end
    end

    describe 'easy setting for sprint' do

      it 'create and delete setting' do
        expect{ post :create, :params => {project_id: project.id, easy_sprint: { name: 'sprint_easy_setting', start_date: Date.today}} }.to change(EasySprint, :count).by(1)
        sprint_id = assigns(:easy_sprint).id
        expect(EasySetting.find_by(name: "easy_sprint_burndown_#{sprint_id}")).not_to be_nil

        expect { delete :destroy, :params => {project_id: project.id, id: sprint_id }}.to change(EasySprint, :count).by(-1)
        expect(EasySetting.find_by(name: "easy_sprint_burndown_#{sprint_id}")).to be_nil
      end
    end

  end

end
