RSpec.describe EasyEntityImportsController, logged: :admin do
  subject { FactoryBot.create(:easy_entity_csv_import, entity_type: "Issue") }
  describe "#index" do
    it "blank query" do
      get :index
      expect(response).to have_http_status :success
    end

    it "with imports" do
      subject
      get :index
      expect(response).to have_http_status :success
    end

  end

  describe "#assign_import_attribute" do

  end

  describe "#update" do
    it "update name" do
      subject.update(name: "Wrong")
      put :update, params: { id: subject, easy_entity_import: { name: "Correct" } }
      expect(response).to redirect_to easy_entity_imports_path
      expect { subject.reload }.to change(subject, :name).from("Wrong").to "Correct"
    end
  end
end