require 'easy_extensions/spec_helper'

describe ProjectsController, logged: :admin do

  let!(:template) { FactoryBot.create(:easy_checklist_template, is_default_for_new_projects: true) }

  it 'create a new project with a checklist template' do
    post :create, params: {project: {name: 'checklist test', enabled_module_names: ['easy_checklists']}, format: 'json'}
    expect(response).to be_successful
    expect(assigns(:project).easy_checklist_templates.count).to eq(1)
  end

  context '#copy' do
    let(:project) { FactoryBot.create(:project, enabled_module_names: ['easy_checklists']) }

    let(:copy_params) {
      {
        "project" => {
            "name"                            => project.name,
            "parent_id"                       => nil,
            "author_id"                       => User.current.id,
            "enabled_module_names"            => project.enabled_module_names,
        },
        "id" => project.id
      }
    }

    it 'a project with a checklist template' do
      expect(project.easy_checklist_templates.count).to eq(1)
      post :copy, params: copy_params
      expect(assigns(:project).easy_checklist_templates.count).to eq(1)
    end
  end
end
