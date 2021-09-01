shared_examples :controller_requirements do |with_artifact|
  describe 'GET #index' do
    it 'should redirect' do
      get :index, params: { project_id: project.id }

      if with_artifact
        expect(response).to have_http_status(200) # success
      elsif User.current.anonymous?
        expect(response).to redirect_to(controller: :account, action: :login, back_url: requirements_project_url(project_id: project.id))
      else
        expect(response).to redirect_to(controller: :re_settings, action: :new, project_id: project.id)
      end
    end
  end

  # it seems that context_menu is not used
  describe 'GET #context_menu' do
    it 'should return no route' do
      expect { get :context_menu, params: { project_id: project.id } }.to raise_error(ActionController::UrlGenerationError)
    end
  end

  describe 'GET #tree' do
    it 'is bad route' do
      expect { get :tree, params: { project_id: project.id } }.to raise_error(ActionController::UrlGenerationError)
    end

    it 'should return 404 Not Found' do
      status = (with_artifact) ? 200 : (defined?(artifact_properties) ? 404 : 302)
      id = with_artifact ? artifact_properties.id : nil

      get :tree, params: { project_id: project.id, mode: 'data', id: id }
      expect(response).to have_http_status(status)

      get :tree, params: { project_id: project.id, mode: 'root', id: id }
      expect(response).to have_http_status(status)

      get :tree, params: { project_id: project.id, mode: 'open', id: id }
      expect(response).to have_http_status(status)

      get :tree, params: { project_id: project.id, mode: 'close', id: id }
      expect(response).to have_http_status(status)

      get :tree, params: { project_id: project.id, mode: 'asdfghjkl', id: id }
      expect(response).to have_http_status(id ? 422 : status)
    end
  end

  # it seems that context_menu is not used
  describe 'GET #context_menu' do
    it 'should return no route' do
      id = (with_artifact && artifact_properties.present?) ? artifact_properties.id : nil
      expect { get :context_menu, params: { project_id: project.id, id: id } }.to raise_error(ActionController::UrlGenerationError)
    end
  end

end