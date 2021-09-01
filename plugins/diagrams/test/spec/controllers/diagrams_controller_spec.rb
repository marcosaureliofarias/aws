require_relative "../spec_helper"

describe DiagramsController, type: :controller do
  context 'permissions', logged: true do
    let(:diagram) { FactoryBot.create(:diagram) }
    let(:xml) { "<root><Diagram>1.0</Diagram></root>" }
    let(:image) { "data:image/jpeg;base64,/9j/" }
    let(:position) { 1 }

    before do
      role = Role.non_member
      role.add_permission!(:manage_diagrams)
      role.reload
    end

    [:index, :show, :generate].each do |action|
      it "allows GET #{action}" do
        get action, params: { id: diagram.id, position: position }

        expect( response ).to have_http_status(200)
      end
    end

    it 'allows GET toggle_position' do
      get :toggle_position, params: { id: diagram.id, position: position, back_url: root_path }

      expect( response ).to have_http_status(302)
    end

    it 'allows POST save' do
      post :save, params: { id: diagram.id, xmlpng: image }

      expect( response ).to have_http_status(204)
    end

    it 'allows DELETE destroy' do
      delete :destroy, params: { id: diagram.id, back_url: root_path }

      expect( response ).to have_http_status(302)
    end

    it 'allows DELETE bulk_destroy' do
      delete :bulk_destroy, params: { ids: [diagram.id], back_url: root_path }

      expect( response ).to have_http_status(302)
    end

    context 'user without manage_diagrams permission' do
      before do
        role = Role.non_member
        role.remove_permission!(:manage_diagrams)
        role.reload
      end

      [:index, :show, :toggle_position, :generate].each do |action|
        it "does not allow GET #{action}" do
          get action, params: { id: diagram.id, position: position }

          expect( response ).to have_http_status(403)
        end
      end

      it 'does not allow POST save' do
        post :save, params: { id: diagram.id, xmlpng: image }

        expect( response ).to have_http_status(403)
      end

      it 'does not allow DELETE destroy' do
        delete :destroy, params: { id: diagram.id, back_url: root_path }

        expect( response ).to have_http_status(403)
      end

      it 'does not allow POST bulk_destroy' do
        delete :bulk_destroy, params: { ids: [diagram.id], back_url: root_path }

        expect( response ).to have_http_status(403)
      end
    end
  end
end