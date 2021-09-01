RSpec.describe ApiDocsController, type: :controller do
  describe "#index" do
    it "render json" do
      # allow(EasySwagger).to receive(:registered_classes).and_return(EasySwagger.built_in_classes.map(&:constantize))
      get :index, params: { format: "json" }
      expect(response).to have_http_status :success
      json = JSON.parse response.body
      expect(json["paths"]).to include /admin\/easy_settings/, /time_entries/, /issues/
    end
  end
end