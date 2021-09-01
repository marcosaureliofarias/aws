class PreDefinedImport < EasyEntityCsvImport
  def predefined?
    true
  end
end
RSpec.describe "easy_entity_imports/show.html.erb" do
  let(:easy_entity_import) { FactoryBot.build_stubbed(:easy_entity_csv_import, id: 1) }

  it "render" do
    assign :easy_entity_import, easy_entity_import

    render
    expect(rendered).to have_selector "#easy_entity_import_source_inputs"
    expect(rendered).to have_selector "select#easy_entity_import_merge_by"
  end

  it "pre-defined without map" do
    assign :easy_entity_import, easy_entity_import.becomes(PreDefinedImport)

    render
    expect(rendered).not_to have_selector "section#easy_entity_import_mappings"
  end

  context "Project" do
    let(:easy_entity_import) { FactoryBot.build_stubbed(:easy_entity_csv_import, entity_type: "Project", id: 2) }
    before(:each) do
      assign :easy_entity_import, easy_entity_import
    end
    it "templates select" do
      render
      expect(rendered).not_to have_selector "select#template_id"
    end
  end


end