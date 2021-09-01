require File.expand_path('../../spec_helper.rb', __FILE__)

describe EasyTestCaseCsvImport do

  def file_fixture(file_name)
    Pathname(File.join(__dir__, "../fixtures/files", file_name))
  end

  let(:test_cases) { double "Attachment", diskfile: file_fixture("test_cases.csv"), filename: "test_cases.csv" }
  let(:test_cases_count) { 2 }

  let(:easy_test_case_csv_import) { FactoryBot.create(:easy_test_case_csv_import) }
  before :each do
    allow(easy_test_case_csv_import).to receive(:attachments).and_return [test_cases]
  end

  it "#create" do
    x = described_class.create(name: "Test import", entity_type: "TestCase")
    expect(x.persisted?).to eq true
  end


  context "#import_importer" do
    let(:assignments) do
      [
          FactoryBot.create(:test_case_import_assignment, easy_entity_import: easy_test_case_csv_import, source_attribute: 0, entity_attribute: "name"),
          FactoryBot.create(:test_case_import_assignment, easy_entity_import: easy_test_case_csv_import, source_attribute: 1, entity_attribute: "scenario"),
          FactoryBot.create(:test_case_import_assignment, easy_entity_import: easy_test_case_csv_import, source_attribute: 2, entity_attribute: "expected_result"),
          FactoryBot.create(:test_case_import_assignment, easy_entity_import: easy_test_case_csv_import, source_attribute: 3, entity_attribute: "project_id"),
          FactoryBot.create(:test_case_import_assignment, easy_entity_import: easy_test_case_csv_import, source_attribute: 4, entity_attribute: "author_id"),
      ]
    end

    let(:project) { FactoryBot.create(:project, id: 11, :add_modules => %w(test_cases)) }
    let!(:role) { FactoryBot.create(:role) }
    let!(:user) { FactoryBot.create(:user, id: 5) }
    let!(:member) { FactoryBot.create(:member, project: project, user: user, roles: [role]) }

    before :each do
      role.add_permission! :import_test_cases
      allow(User).to receive(:current).and_return(user)
      allow(easy_test_case_csv_import).to receive(:easy_entity_import_attributes_assignments).and_return(assignments)
    end

    it "try import" do
      expect { easy_test_case_csv_import.import_importer }.to change(TestCase, :count).by(test_cases_count)

      tc1, tc2, tc_others = TestCase.all.order(:name).to_a
      expect(tc1.name).to eq 'TC 1'
      expect(tc2.name).to eq 'TC 2'
    end

  end

end
