class EasySwaggerDummyController < ApplicationController
  include EasySwagger::BaseController
end

RSpec.describe EasySwagger::BaseController, type: :controller do
  it ".entity" do
    expect(EasySwaggerDummyController.entity).to eq "EasySwaggerDummy"
  end

  it ".add_tag" do
    EasySwaggerDummyController.add_tag name: "custom_name", description: "dummy desc"
  end

  describe ".swagger_me" do
    it "include not register" do
      expect(EasySwagger.registered_classes).not_to include "EasySwaggerDummyController"
    end
    it "registered" do
      EasySwaggerDummyController.swagger_me
      expect(EasySwagger.registered_classes).to include EasySwaggerDummyController
    end
  end

  describe ".add_includes" do
    before { EasySwaggerDummyController.swagger_me }
    it "empty" do
      EasySwaggerDummyController.add_includes
    end

    it "with hash" do
      EasySwaggerDummyController.add_includes groups: "Sojka"
    end
  end

  it ".add_action" do
    EasySwaggerDummyController.swagger_me

    EasySwaggerDummyController.add_action "bear.{format}" do
      operation :get do
        key :summary, "Get bear"
        parameter do
          key :name, "id"
          key :in, "path"
          key :required, true
          schema type: "string"
        end
        response 200 do
        end
      end
    end
    EasySwaggerDummyController.add_action "/dummies/bear.{format}" do
      operation :get do
        key :summary, "Get bear"
        parameter do
          key :name, "id"
          key :in, "path"
          key :required, true
          schema type: "string"
        end
        response 200 do
        end
      end
    end
    data = Swagger::Blocks::InternalHelpers.parse_swaggered_classes(ApiDocsController.for_documentation)
    expect(data[:path_nodes].keys).to include :"/easy_swagger_dummies/bear.{format}"
    expect(data[:path_nodes].keys).to include :"/dummies/bear.{format}"
  end
end