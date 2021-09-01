RSpec.describe EasySwagger::ApplicationHelper do
  include_context "DummyEntitySwaggerSpec"
  describe "#render_api" do
    let(:builder) { Redmine::Views::Builders::Json.new(spy(params: {}), response) }
    it "render json for dummy" do
      helper.render_api_from_swagger(entity, builder)
      expect(builder.output).to include "id", "author", "created_at"
    end
    it "easy_external_id not in result" do
      helper.render_api_from_swagger(entity, builder)
      expect(builder.output).not_to include "easy_external_id"
    end
    it "condition works" do
      User.current.id = 0
      helper.render_api_from_swagger(entity, builder)
      expect(builder.output).to include "easy_external_id"
    end
  end
end