RSpec.describe "/easy_entity_imports", logged: :admin do
  let(:import) { FactoryBot.create(:easy_entity_csv_import) }
  describe "list of imports" do

    it "without entities" do
      get easy_entity_imports_path
      expect(response).to have_http_status :success
    end


    it "with entities" do
      import
      get easy_entity_imports_path
      expect(response).to have_http_status :success
    end

  end
end