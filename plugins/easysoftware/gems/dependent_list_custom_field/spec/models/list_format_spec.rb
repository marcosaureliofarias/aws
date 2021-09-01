RSpec.describe Redmine::FieldFormat::DependentList do
  include_context "depended custom field"
  shared_examples "check data-dependency attribute" do
    it "render select_edit_tag with data attribute" do
      custom_value = double("CustomValue", custom_field: custom_field, value: "Skoda")
      view = spy "View", options_for_select: "<options/>", content_tag: ""
      expect(view).to receive(:select_tag).with("automaker", kind_of(String), hash_including("data-dependency"))
      custom_field.format.select_edit_tag view, "tag_ID", "automaker", custom_value
    end
  end
  it_should_behave_like "check data-dependency attribute" do
    let(:custom_field) { automaker_cf }
  end
  it_should_behave_like "check data-dependency attribute" do
    let(:custom_field) { brand_cf }
  end

end