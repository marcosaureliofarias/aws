require_relative '../spec_helper'

RSpec.describe Issue, type: :model do
  let!(:user) { FactoryGirl.create(:user) }

  context 'does not include issues from archived projects' do
    let!(:archived_project) { FactoryGirl.create(:project, status: Project::STATUS_ARCHIVED, number_of_issues: 0, enabled_module_names: ['issue_tracking'], members: [User.current]) }
    let!(:issue) { FactoryGirl.create(:issue, project: project, author: user) }
    let!(:archived_issue) { FactoryGirl.create(:issue, project: archived_project, author: user) }
    let!(:project) { FactoryGirl.create(:project, number_of_issues: 0, enabled_module_names: ['issue_tracking'], members: [User.current]) }

    before(:each) do
      EasyOrgChartNode.create_nodes!({'id' => User.current.to_gid_param, 'children' => {'1' => {'id' => user.to_gid_param}}})
    end

    it 'regular user', logged: true do
      expect(Issue.visible.to_a).to match_array([project.issues.first])
    end

    it 'admin user', logged: :admin do
      expect(Issue.visible.to_a).to match_array([project.issues.first])
    end
  end

  context 'shared subordinates permissions', logged: true do
    before :each do
      allow(User).to receive(:current).and_return(current_user)
      # by default factory role created with all the permissions
    end

    let!(:current_user) { FactoryGirl.create(:user) }
    let!(:project) { FactoryGirl.create(:project, number_of_issues: 0, enabled_module_names: ['issue_tracking'], members: [user]) }
    let!(:my_project) { FactoryGirl.create(:project, number_of_issues: 0, enabled_module_names: ['issue_tracking'], members: [current_user]) }
    let!(:my_issue) { FactoryBot.create(:issue, project: my_project, assigned_to: current_user) }
    let!(:subordinates_issue) { FactoryBot.create(:issue, author: user, project: project) }

    context 'visible?' do
      it 'forbidden' do
        EasyOrgChartNode.create_nodes!({'id' => current_user.to_gid_param, 'children' => {'1' => {'id' => user.to_gid_param}}})

        with_easy_settings('easy_org_chart_share_subordinates_access' => 'forbidden') do
          expect(my_issue.visible?).to eq(true)
          expect(subordinates_issue.visible?).to eq(false)
        end
      end

      it 'shared direct subordinate\'s access' do
        EasyOrgChartNode.create_nodes!({'id' => current_user.to_gid_param, 'children' => {'1' => {'id' => user.to_gid_param}}})

        with_easy_settings('easy_org_chart_share_subordinates_access' => 'direct_subordinates') do
          expect(my_issue.visible?).to eq(true)
          expect(subordinates_issue.visible?).to eq(true)
        end
      end

      it 'shared subordinate\'s tree access' do
        user1 = FactoryBot.create(:user)
        project1 = FactoryGirl.create(:project, enabled_module_names: ['issue_tracking'], members: [user1])

        subordinates_issue1 = FactoryBot.create(:issue, assigned_to: user1, project: project1)
        tree = {'id' => user.to_gid_param, 'children' => {'1' => {'id' => user1.to_gid_param}}}
        EasyOrgChartNode.create_nodes!({'id' => current_user.to_gid_param, 'children' => {'1' => tree}})

        with_easy_settings('easy_org_chart_share_subordinates_access' => 'subordinates_tree') do
          expect(my_issue.visible?).to eq(true)
          expect(subordinates_issue.visible?).to eq(true)
          expect(subordinates_issue1.visible?).to eq(true)
        end
      end
    end

    context 'scope :visible' do
      it 'forbidden' do
        EasyOrgChartNode.create_nodes!({'id' => current_user.to_gid_param, 'children' => {'1' => {'id' => user.to_gid_param}}})

        with_easy_settings('easy_org_chart_share_subordinates_access' => 'forbidden') do
          expect(Issue.visible.to_a).to match_array([my_issue])
        end
      end

      it 'shared direct subordinate\'s access' do
        EasyOrgChartNode.create_nodes!({'id' => current_user.to_gid_param, 'children' => {'1' => {'id' => user.to_gid_param}}})

        with_easy_settings('easy_org_chart_share_subordinates_access' => 'direct_subordinates') do
          expect(Issue.visible.to_a).to match_array([my_issue, subordinates_issue])
        end
      end

      it 'shared subordinate\'s tree access' do
        user1 = FactoryBot.create(:user)
        project1 = FactoryGirl.create(:project, number_of_issues: 0, enabled_module_names: ['issue_tracking'], members: [user1])

        subordinates_issue1 = FactoryBot.create(:issue, assigned_to: user1, project: project1)
        tree = {'id' => user.to_gid_param, 'children' => {'1' => {'id' => user1.to_gid_param}}}
        EasyOrgChartNode.create_nodes!({'id' => current_user.to_gid_param, 'children' => {'1' => tree}})

        with_easy_settings('easy_org_chart_share_subordinates_access' => 'subordinates_tree') do
          expect(Issue.visible.to_a).to match_array([my_issue, subordinates_issue, subordinates_issue1])
        end
      end
    end
  end
end
