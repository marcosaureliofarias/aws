class DummySwaggerController

end
RSpec.describe EasySwagger do
  it ".register" do
    expect { EasySwagger.register "DummySwaggerController" }.to change(EasySwagger.config.class_names_store, :size)
  end

  it ".registered_classes" do
    expect(EasySwagger.registered_classes).to include EasySwagger::EasySettingsController
  end

end