shared_examples :test_cases_csv_import_controller_requests do |type, entity_type, has_permission|

  context 'no entity required' do
    describe 'GET #index' do
      it 'lists available imports' do
        url = test_cases_csv_import_index_url
        get :index

        if has_permission
          expect(response).to have_http_status(200) # success
        elsif defined?(user)
          expect(response).to have_http_status(403) # forbidden
        else
          expect(response).to have_http_status(302) # redirect to login page
          expect(response).to redirect_to(signin_path(back_url: url))
        end
      end
    end

    describe 'GET #new' do
      it 'shows new dialog' do
        # get :new, type: 'EasyEntityImports::EasyTestCaseCsvImport'
        # get :new, params: { type: 'EasyEntityImports::EasyTestCaseCsvImport' }
        url = new_test_cases_csv_import_url
        get :new

        if has_permission
          expect(response).to have_http_status(200) # success
        elsif defined?(user)
          expect(response).to have_http_status(403) # forbidden
        else
          expect(response).to have_http_status(302) # redirect
          expect(response).to redirect_to(signin_path(back_url: url))
        end
      end
    end

    describe 'POST #create' do
      it 'creates new import' do
        url = test_cases_csv_import_index_url
        post :create, params: { type: type.name, easy_test_case_csv_import: { name: 'Testing import', entity_type: entity_type }  }

        if has_permission
          expect(response).to have_http_status(302) # redirect
          expect(response.location).to match(Regexp.new("#{url}/\\d+"))
        elsif defined?(user)
          expect(response).to have_http_status(403) # forbidden
        else
          expect(response).to have_http_status(302) # redirect
          expect(response).to redirect_to(signin_path(back_url: url))
        end
      end
    end
  end

  context 'entity required' do
    let(:entity) {
      entity = type.new(name: 'Testing import', entity_type: entity_type)
      entity.save!
      entity
    }

    describe 'GET #show' do
      it 'shows entity' do
        url = test_cases_csv_import_url(entity)
        get :show, params: { id: entity.id }

        if has_permission
          expect(response).to have_http_status(200) # success
        elsif defined?(user)
          expect(response).to have_http_status(403) # forbidden
        else
          expect(response).to have_http_status(302) # redirect
          expect(response).to redirect_to(signin_path(back_url: url))
        end
      end
    end

    describe 'GET #edit' do
      it 'shows edit form' do
        url = edit_test_cases_csv_import_url(entity)
        get :edit, params: { id: entity.id }

        if has_permission
          expect(response).to have_http_status(200) # success
        elsif defined?(user)
          expect(response).to have_http_status(403) # forbidden
        else
          expect(response).to have_http_status(302) # redirect
          expect(response).to redirect_to(signin_path(back_url: url))
        end
      end
    end

    describe 'PUT #update' do
      it 'updates import' do
        url = test_cases_csv_import_url(entity)
        put :update, params: { id: entity.id, type: type.name, easy_test_case_csv_import: { name: 'Testing import 2', entity_type: entity_type }  }

        if has_permission
          expect(response).to have_http_status(302) # redirect
          expect(response.location).to match(test_cases_csv_import_index_url)
        elsif defined?(user)
          expect(response).to have_http_status(403) # forbidden
        else
          expect(response).to have_http_status(302) # redirect
          expect(response).to redirect_to(signin_path(back_url: url))
        end
      end
    end

    describe 'DELETE #destroy' do
      it 'deletes import' do
        url = test_cases_csv_import_url(entity)
        delete :destroy, params: { id: entity.id }

        if has_permission
          expect(response).to have_http_status(303) # redirect
          expect(response.location).to match(test_cases_csv_import_index_url)
        elsif defined?(user)
          expect(response).to have_http_status(403) # forbidden
        else
          expect(response).to have_http_status(302) # redirect
          expect(response).to redirect_to(signin_path(back_url: url))
        end
      end
    end

    describe 'POST #fetch_preview' do
      it 'shows import preview' do
        url = fetch_preview_test_cases_csv_import_url(entity)
        post :fetch_preview, params: { id: entity.id }

        if has_permission
          expect(response).to have_http_status(200) # redirect
        elsif defined?(user)
          expect(response).to have_http_status(403) # forbidden
        else
          expect(response).to have_http_status(302) # redirect
          expect(response).to redirect_to(signin_path(back_url: url))
        end
      end
    end

    describe 'POST #import' do
      it 'run import' do
        url = import_test_cases_csv_import_url(entity)
        post :import, params: { id: entity.id }

        if has_permission
          expect(response).to have_http_status(200) # redirect
        elsif defined?(user)
          expect(response).to have_http_status(403) # forbidden
        else
          expect(response).to have_http_status(302) # redirect
          expect(response).to redirect_to(signin_path(back_url: url))
        end
      end
    end
  end
end
