require 'easy_extensions/spec_helper'

describe IssuesHelper do
  let(:issue_status_normal) { FactoryBot.create(:issue_status, is_closed: false) }
  let!(:project) { FactoryBot.create(:project, members: [User.current]) }
  let(:easy_helpdesk_project) { FactoryBot.create(:easy_helpdesk_project, project: project) }
  let(:easy_helpdesk_project_sla) { FactoryBot.create(:easy_helpdesk_project_sla, hours_to_response: 3, hours_to_solve: 2, easy_helpdesk_project: easy_helpdesk_project) }
  let(:issue) { FactoryBot.create(:issue, project: project, status: issue_status_normal, priority: easy_helpdesk_project_sla.priority) }
  
  context 'Permission :view_easy_helpdesk_sla', logged: true do
    it 'admin view SLA' do
      expect(helper).to receive(:render_issue_easy_helpdesk_sla_response_info)
      expect(helper).to receive(:render_issue_easy_helpdesk_sla_resolve_info)
      User.current.as_admin do
        helper.render_issue_easy_helpdesk_info(issue)
      end
    end

    it 'Current user with SLA permission' do
      expect(helper).to receive(:render_issue_easy_helpdesk_sla_response_info)
      expect(helper).to receive(:render_issue_easy_helpdesk_sla_resolve_info)
      User.current.roles.first.add_permission!(:view_easy_helpdesk_sla)
      helper.render_issue_easy_helpdesk_info(issue)
    end
    
    it 'Current user is not able to view SLA' do
      User.current.roles.first.remove_permission!(:view_easy_helpdesk_sla)
      expect(helper).not_to receive(:render_issue_easy_helpdesk_sla_response_info)
      expect(helper).not_to receive(:render_issue_easy_helpdesk_sla_resolve_info)
      helper.render_issue_easy_helpdesk_info(issue)
    end
  end

  context 'settings project sla hours', logged: :admin do
    it 'only hours_to_response' do
      easy_helpdesk_project_sla.update(hours_to_solve: nil)
      expect(helper).to receive(:render_issue_easy_helpdesk_sla_response_info)
      expect(helper).not_to receive(:render_issue_easy_helpdesk_sla_resolve_info)
      helper.render_issue_easy_helpdesk_info(issue)
    end

    it 'only hours_to_solve' do
      easy_helpdesk_project_sla.update(hours_to_response: nil)
      expect(helper).not_to receive(:render_issue_easy_helpdesk_sla_response_info)
      expect(helper).to receive(:render_issue_easy_helpdesk_sla_resolve_info)
      helper.render_issue_easy_helpdesk_info(issue)
    end
  end
end
