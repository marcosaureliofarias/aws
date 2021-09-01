shared_examples :crud_settings do |confirmed|
  describe 'GET #new' do
    it 'shows setup page or redirects to login' do
      get :new, params: { project_id: project.id }

      if User.current && !User.current.anonymous?
        expect(response).to have_http_status(200) # success
      else
        expect(response).to redirect_to(controller: :account, action: :login, back_url: requirements_settings_firstload_project_url(project_id: project.id))
      end
    end
  end

  describe 'GET #edit' do
    it 'redirects to login or shows edit page' do
      get :edit, params: { project_id: project.id }

      if confirmed.present?
        expect(response).to have_http_status(200)
      elsif User.current && !User.current.anonymous?
        expect(response).to have_http_status(302)
      else
        expect(response).to redirect_to(controller: :account, action: :login, back_url: requirements_settings_project_url(project_id: project.id))
      end
    end
  end

  describe 'POST #update' do
    it 'redirects to login or to requirements page' do
      if confirmed
        post :update, params: { project_id: project.id }

        expect(response).to redirect_to(controller: :requirements, action: :index, project_id: project.id)
      else
        post :update, params: { project_id: project.id, firstload: '1' }

        if User.current && !User.current.anonymous?
          expect(response).to redirect_to(action: :new, project_id: project.id)
        else
          expect(response).to redirect_to(controller: :account, action: :login, back_url: requirements_settings_project_url(project_id: project.id))
        end
      end
    end

    it 'should use default parameters' do
      post :create, params: { project_id: project.id, name: 'Project X' }

      if User.current && !User.current.anonymous?
        expect(response).to redirect_to(controller: :requirements, action: :index, project_id: project.id)
      else
        expect(response).to redirect_to(controller: :account, action: :login, back_url: requirements_settings_firstload_project_url(project_id: project.id))
      end
    end

    it 'should save default configuration or redirects to login' do
      post :create, params: {
          project_id: project.id,
          name: 'Project Y',
          re_artifact_order: '{}',
          re_relation_order: '{}',
          re_visualization_settings: {},
          re_settings: {},
          re_artifact_configs: {}
        }

      if User.current && !User.current.anonymous?
        expect(response).to redirect_to(controller: :requirements, action: :index, project_id: project.id)
      else
        expect(response).to redirect_to(controller: :account, action: :login, back_url: requirements_settings_firstload_project_url(project_id: project.id))
      end
    end
  end
end