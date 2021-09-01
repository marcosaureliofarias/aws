require_relative '../spec_helper'

describe EasyUserTypesController, type: :controller, logged: true do

  context '#easy_lesser_admin_permissions' do

    it 'without permissions' do
      get :index
      expect(response.status).to eq(403)
    end

    it 'with permission' do
      allow_any_instance_of(User).to receive_messages(easy_lesser_admin?: true, easy_lesser_admin_permissions: [:easy_user_types])
      get :index
      expect(response.status).to eq(200)
    end

  end

end