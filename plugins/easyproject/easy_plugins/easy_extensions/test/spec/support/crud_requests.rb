RSpec.shared_context 'a requests actions' do |factory, permissions|
  let(:entity) { FactoryBot.create(factory) }
  let(:entities_list) { FactoryBot.create_list(factory, 2) }
  let(:admin) { FactoryBot.create :admin_user }
  let(:user) { FactoryBot.create :user }

  def api_key
    user.api_key
  end

  def assign_permissions(permissions)
    Role.non_member.add_permission! *permissions
  end

  describe '#index' do
    shared_examples "index actions" do |response_code|
      it "html" do
        get polymorphic_path(factory.to_s.pluralize)
        expect(response).to have_http_status(response_code)
      end
      it "json", null: true do
        with_settings rest_api_enabled: 1 do
          get polymorphic_path(factory.to_s.pluralize, format: "json", key: api_key)
          expect(response).to have_http_status(response_code)
        end
      end
    end

    before { entities_list }
    context "without permissions", logged: true do
      it_behaves_like "index actions", :forbidden
    end
    context "admin", logged: :admin do
      def api_key
        admin.api_key
      end
      it_behaves_like "index actions", :successful
    end
    context "role with permissions", logged: true do
      before { assign_permissions(permissions) }
      it_behaves_like "index actions", :successful
    end
  end
  describe '#show' do
    shared_examples "show actions" do |response_code|
      it "html" do
        get polymorphic_path(entity)
        expect(response).to have_http_status(response_code)
      end
      it "json", null: true do
        with_settings rest_api_enabled: 1 do
          get polymorphic_path(entity, format: "json", key: api_key)
          expect(response).to have_http_status(response_code)
          expect(response.body).to include "id", entity.id.to_s if response.successful?
        end
      end
    end

    before { entity }
    context "without permissions", logged: true do
      it_behaves_like "show actions", :forbidden
    end
    context "admin", logged: :admin do
      def api_key
        admin.api_key
      end
      it_behaves_like "show actions", :successful
    end
    context "role with permissions", logged: true do
      before { assign_permissions(permissions) }
      it_behaves_like "show actions", :successful
    end
  end

  #describe '#destroy' do
  #
  #end
  #
  #it '#destroy' do
  #  entity # touch
  #  expect { delete polymorphic_path(entity) }.to change(entity.class, :count).by(-1)
  #end
  #
  #context 'json' do
  #
  #  it '#index' do
  #    entities_list
  #    get polymorphic_path(factory.to_s.pluralize, format: "json")
  #    expect(response).to have_http_status(:success)
  #  end
  #
  #  it '#show' do
  #    get polymorphic_path(entity)
  #    expect(response).to have_http_status(:success)
  #    expect(response.body).to include "id", entity.id.to_s
  #  end
  #end

end