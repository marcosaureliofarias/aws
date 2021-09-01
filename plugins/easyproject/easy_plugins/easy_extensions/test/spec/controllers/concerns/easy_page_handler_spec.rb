require 'easy_extensions/spec_helper'

RSpec.describe EasyExtensions::EasyPageHandler, type: :controller, logged: :admin do

  controller do
    EasyExtensions::EasyPageHandler.register_for(self, {
        page_name:   'test-page',
        show_action: :index,
        edit_action: :layout
    })

    def index
      head :ok
    end
  end

  describe 'EasyPageHandler inclusion' do

    it 'defines controller action and before_action' do
      expect(controller.action_methods).to include('layout')
      expect(controller).to receive(:find_easy_page_by).with({ page_name: 'test-page' })
      expect(controller).to receive(:allowed_to_page_show?).and_return(true)
      get :index
    end

  end

end
