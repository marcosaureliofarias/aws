RSpec.describe EasySwagger::BaseModel do
  describe "#response_schema" do
    it "call without block should return response scheme" do
      expect(DummyEntitySwaggerSpec.response_schema).to be_a EasySwagger::Blocks::SchemaNode
    end
  end

  describe "#to_json", logged: :admin do
    let(:user) { FactoryBot.create :user }
    it "render json" do
      json = EasySwagger::User.to_json(user)
      expect(json).to be_a String
      expect(json).to include "user"
      expect(json).to match "\"mail\":\"#{user.mail}\""
    end
  end

  describe "#to_h", logged: :admin do
    let(:user) { FactoryBot.create :user }
    it "render ruby hash" do
      json = EasySwagger::User.to_h(user)
      expect(json).to be_a Hash
      expect(json).to include mail: user.mail
    end
  end
end
