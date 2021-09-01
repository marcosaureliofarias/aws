require 'easy_extensions/spec_helper'

describe TemplatesController, logged: :admin do
  let(:template) { FactoryBot.create(:project, members: [User.current], easy_is_easy_template: true) }
  let(:project) { FactoryBot.create(:project, members: [User.current]) }
  let(:custom_field) { FactoryBot.create(:project_custom_field, field_format: 'text', is_required: true) }

  it 'wrong params' do
    post :make_project_from_template, :params => { :id => template, :template => { :project => [{ :id => 123, :identifier => 'xxx', :custom_field_values => { '1' => 'x' } }] } }
    expect(response).not_to have_http_status(500)
  end

  it 'invalid template' do
    template.name = ''
    template.save(:validate => false)
    post :make_project_from_template, :params => { :id => template, :template => { :start_date => '2017-03-16', :update_dates => '1', :change_issues_author => '', :assign_entity => { :type => '', :id => '' } } }
    expect(response).not_to have_http_status(500)
  end

  it 'without custom_field_values' do
    post :make_project_from_template, :params => { :id => template, :template => { :project => [{ :id => 123, :identifier => 'xxx' }] } }
    expect(response).not_to have_http_status(500)
  end

  it 'valid project params' do
    projects_attributes = [{ :id => '123', :identifier => template.identifier, :custom_field_values => { '1' => 'x' } }]
    allow_any_instance_of(Project).to receive(:project_with_subprojects_from_template).and_return([nil, [], [nil]])
    post :make_project_from_template, :params => {
        :id       => template,
        :template => {
            :start_date => '2017-03-16',
            :project    => projects_attributes
        }
    }
    expect(assigns(:source_project)).to have_received(:project_with_subprojects_from_template).with(anything, projects_attributes, anything)
  end

  it 'required custom fields' do
    projects_attributes = [{ id: template.id, name: 'new', custom_field_values: { custom_field.id.to_s => 'x' } }]
    expect {
      post :make_project_from_template, params: {
          id:       template,
          template: {
              start_date: '2017-03-16',
              project:    projects_attributes
          },
          format:   'json'
      }
    }.to change(Project, :count).by(1)

    expect(assigns(:source_project).valid?).to eq(false)
    expect(assigns(:new_project).valid?).to eq(true)
  end

  context 'with settings' do
    it 'match starting dates' do
      with_time_travel(-1.month) { template }
      issue               = template.issues.first
      projects_attributes = [{ id: '123', identifier: template.identifier, custom_field_values: { '1' => 'x' } }]
      allow_any_instance_of(Project).to receive(:project_with_subprojects_from_template).and_return([nil, [], [nil]])
      post :make_project_from_template, params: {
          id:       template,
          template: {
              dates_settings: 'match_starting_dates',
              start_date:     Date.today,
              project:        projects_attributes
          }
      }
      expected_duration = issue.duration.to_f
      new_issue         = assigns(:new_project).issues.where(subject: issue.subject).first
      expect(new_issue.duration).to eq(expected_duration)
    end

    context 'do not change any dates' do
      include_examples :make_project_from_template, Date.new(2019, 01, 01), Date.new(2019, 07, 30), 'do_not_change_any_dates', Date.new(2019, 01, 01)
    end
    context 'update dates' do
      include_examples :make_project_from_template, Date.new(2019, 01, 01), Date.new(2019, 07, 30), 'update_dates', Date.new(2019, 07, 30)
      include_examples :copy_project_from_template, Date.new(2019, 01, 01), Date.new(2019, 07, 30), 'update_dates', Date.new(2019, 07, 30)
      it_behaves_like :make_project_from_template, Date.new(2019, 01, 01), Date.new(2019, 07, 30), 'update_dates', Date.new(2019, 07, 30) do
        let!(:subtemplate) { FactoryBot.create(:project, members: [User.current], easy_is_easy_template: true, parent: template) }
      end
    end
    context 'match starting dates' do
      it_behaves_like :copy_project_from_template, Date.new(2019, 01, 01), Date.new(2019, 07, 30), 'match_starting_dates', Date.new(2019, 01, 01)
    end
  end
end
