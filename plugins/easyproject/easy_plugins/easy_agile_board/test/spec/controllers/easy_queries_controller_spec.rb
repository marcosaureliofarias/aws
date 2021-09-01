require 'easy_extensions/spec_helper'

describe EasyQueriesController, logged: :admin do

  describe 'EasyAgileBoard query' do
    let!(:query) { FactoryGirl.create(:easy_agile_board_query) }
    let(:backlog_url_hash) { { controller: :easy_agile_board, action: :backlog, id: 1, sprint_id: 1 } }

    context 'with existing sprint' do
      render_views
      let(:sprint_with_issues) { FactoryGirl.create(:easy_sprint, issues: FactoryGirl.create_list(:issue, 1)) }

      it 'returns output data' do
        get :output_data, params: {set_filter: 1, type: 'EasyAgileBoardQuery', output: 'scrum', easy_sprint_id: sprint_with_issues.id.to_s, format: :json}
        expect(response).to be_successful
      end
    end

    context 'is redirected after destroy' do
      it 'with back_url to backlog' do
        delete :destroy, params: {id: query.id, back_url: easy_agile_board_backlog_url(backlog_url_hash)}
        expect(response).to redirect_to(backlog_url_hash)
      end

      it 'without back_url to agile board' do
        delete :destroy, params: {id: query.id}
        expect(response).to redirect_to(controller: :easy_agile_board, action: :show, id: query.project_id)
      end
    end

    it 'filter values with cross project' do
      get :filter_values, params: {dont_use_project: 1, set_filter: 1, type: 'EasyAgileBoardQuery', filter_name: 'category_id', format: :json}
      expect(response).to be_successful
    end

    it 'output data with cross project' do
      project = FactoryBot.create(:project)
      sprint = FactoryBot.create(:easy_sprint)
      sprint_cross = FactoryBot.create(:easy_sprint, cross_project: true)
      base_params = {easy_query_type: 'EasyAgileBoardQuery', output: 'scrum', project_id: project.id, format: 'json'}
      get :output_data, params: {easy_sprint_id: sprint.id}.merge(base_params)
      expect(assigns(:easy_query).dont_use_project).not_to eq(true)
      get :output_data, params: {easy_sprint_id: sprint_cross.id}.merge(base_params)
      expect(assigns(:easy_query).dont_use_project).to eq(true)
    end
  end

end
