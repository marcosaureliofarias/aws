RSpec.describe "easy_entity_imports/edit.html.erb" do
  subject { FactoryBot.build_stubbed(:easy_entity_csv_import, id: 1) }

  it "form fields with correct name" do
    assign :easy_entity_import, subject
    assign :available_entity_types, []
    render

    expect(rendered).to include "easy_entity_import[name]"
  end
end