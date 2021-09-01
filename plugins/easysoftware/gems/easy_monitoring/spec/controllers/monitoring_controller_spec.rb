RSpec.describe EasyMonitoring::MonitoringController, type: :controller do
  routes { EasyMonitoring::Engine.routes }
  include_context 'configure metadata'
  describe "#monitoring" do
    it "html" do
      get :monitoring
      expect(response).to have_http_status :success
    end
    it "json" do
      get :monitoring, params: { format: "json" }
      expect(response).to have_http_status :success
      expect(response.body).to include "host_name"
    end
  end

  describe "#server_resources" do
    context "json" do
      it "return app memory usage" do
        expect(EasyMonitoring::ApplicationMemory).to receive(:usage_by_proc).and_return 2048.0
        get :server_resources, params: { format: "json" }
        expect(response).to have_http_status :success
        expect(response.body).to eq({ easy_web_application: { memory: 2048.0 } }.to_json)
      end
    end
  end
end