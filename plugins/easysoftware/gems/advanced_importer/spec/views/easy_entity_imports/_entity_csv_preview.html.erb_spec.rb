RSpec.describe "easy_entity_imports/previews/_easy_entity_csv_preview.html.erb" do
  let(:easy_entity_import) { FactoryBot.build_stubbed(:easy_entity_csv_import, id: 1) }

  def file_fixture(file_name)
    Pathname(File.join(__dir__, "../../fixtures/files", file_name))
  end

  subject do
    render partial: "easy_entity_imports/previews/easy_entity_csv_preview", locals: { easy_entity_import: easy_entity_import }
    rendered
  end

  it "render without proceed preview" do
    is_expected.to be_blank
  end

  it "render preview" do
    expect(easy_entity_import).to receive(:process_preview_file).and_call_original
    easy_entity_import.preview_for_file double("Attachment", diskfile: file_fixture("issues1.csv"))
    is_expected.to include '<ol start="0">'
  end
end