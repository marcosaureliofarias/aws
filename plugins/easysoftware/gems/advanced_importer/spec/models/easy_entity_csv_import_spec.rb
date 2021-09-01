RSpec.describe EasyEntityCsvImport do

  def file_fixture(file_name)
    Pathname(File.join(__dir__, "../fixtures/files", file_name))
  end

  let(:projects_file) { File.open file_fixture("projects1.csv") }
  let(:file) { File.open file_fixture("issues1.csv") }
  subject do
    s = FactoryBot.build_stubbed(:easy_entity_csv_import, entity_type: "Issue")
    s.set_variables
    allow(s).to receive(:attachments).and_return [file]
    s
  end

  let(:project_import) do
    s = FactoryBot.build_stubbed(:easy_entity_csv_import, entity_type: "Project")
    s.set_variables
    allow(s).to receive(:template).and_return template
    allow(s).to receive(:attachments).and_return [projects_file]
    s
  end

  let(:template) { FactoryBot.create(:project, easy_is_easy_template: true, easy_start_date: '2018-03-02') }
  let(:priority) { FactoryBot.create(:issue_priority, name: "Extra") }
  let(:tracker) { FactoryBot.create(:tracker) }
  let(:project) { FactoryBot.create(:project) }
  let(:user) { FactoryBot.create(:author, easy_external_id: 5) }
  let(:assignments) do
    [
      FactoryBot.build_stubbed(:import_assignment, easy_entity_import: subject, source_attribute: 0, entity_attribute: "easy_external_id"),
      FactoryBot.build_stubbed(:import_assignment, easy_entity_import: subject, source_attribute: 1, entity_attribute: "subject"),
      FactoryBot.build_stubbed(:import_assignment, easy_entity_import: subject, source_attribute: 2, entity_attribute: "author_id", allow_find_by_external_id: true),
      FactoryBot.build_stubbed(:import_assignment, easy_entity_import: subject, source_attribute: 3, entity_attribute: "priority_id"),
      FactoryBot.build_stubbed(:import_assignment, easy_entity_import: subject, source_attribute: 4, entity_attribute: "project_id", is_custom: true, value: project.id),
      FactoryBot.build_stubbed(:import_assignment, easy_entity_import: subject, entity_attribute: "tracker_id", is_custom: true, value: tracker.id)
    ]
  end
  let(:project_assignments) do
    [
      FactoryBot.build_stubbed(:import_assignment, easy_entity_import: project_import, source_attribute: 0, entity_attribute: "easy_external_id"),
      FactoryBot.build_stubbed(:import_assignment, easy_entity_import: project_import, source_attribute: 1, entity_attribute: "name"),
      FactoryBot.build_stubbed(:import_assignment, easy_entity_import: project_import, source_attribute: 2, entity_attribute: "start_date")
    ]
  end

  def make_map
    user
    priority
    allow(subject).to receive(:easy_entity_import_attributes_assignments).and_return(assignments)
  end

  def make_project_map
    allow(project_import).to receive(:easy_entity_import_attributes_assignments).and_return(project_assignments)
  end

  describe "#import" do

    context "issue" do

      it "without map" do
        expect { subject.import(file) }.to raise_exception ActiveRecord::NotNullViolation
      end

      it "with advanced mapping" do
        make_map
        expect { subject.import(file) }.to change(Issue, :count).by 1
      end

    end

    context "project", logged: :admin do

      it "without map" do
        expect { subject.import(projects_file) }.to raise_exception ActiveRecord::NotNullViolation
      end

      it "with advanced mapping" do
        make_project_map
        expect { project_import.import(projects_file) }.to change(Project, :count).by 2
      end

    end

    it "Issue with status" do
      FactoryBot.create(:issue_status)
      status = FactoryBot.create(:issue_status, name: "Closed", is_closed: true)
      assignments.unshift FactoryBot.build_stubbed(:import_assignment, easy_entity_import: subject, source_attribute: 5, entity_attribute: "status_id")
      make_map
      expect { subject.import(file) }.to change(Issue, :count).by 1
      issue = Issue.last
      expect(issue).to have_attributes status_id: status.id
    end

  end

  describe "#prepare_entity" do

    it "regularly new" do
      expect(subject.prepare_entity("x1")).to be_a Issue
      expect(subject.prepare_entity("x1")).to have_attributes easy_external_id: nil
    end

    it "update existing" do
      FactoryBot.create(:issue, easy_external_id: "x1")
      expect(subject.prepare_entity("x1")).to have_attributes easy_external_id: "x1"
    end

    context "Project" do
      subject { FactoryBot.build_stubbed(:easy_entity_csv_import, entity_type: "Project") }
      it "without template" do
        expect(subject.prepare_entity("x1")).to be_a Project
        expect(subject.prepare_entity("x1").enabled_module_names).to include *%w[time_tracking news calendar]
      end

      it "with template" do
        allow(subject).to receive(:template).and_return FactoryBot.build_stubbed(:project, enabled_module_names: %w[time_tracking])
        expect(subject.prepare_entity("x1")).to have_attributes enabled_module_names: %w[time_tracking]
      end
    end
  end

  describe "#ensure_attribute_value" do
    context "basic attribute" do
      it "assign string" do
        attributes = {}
        att = FactoryBot.build_stubbed(:import_assignment, easy_entity_import: subject, entity_attribute: "subject")

        subject.ensure_attribute_value(attributes, att, "5penez")
        expect(attributes).to include "subject" => "5penez"
      end

      it "assign blank" do
        attributes = {}
        att = FactoryBot.build_stubbed(:import_assignment, easy_entity_import: subject, entity_attribute: "subject")

        subject.ensure_attribute_value(attributes, att, "")
        expect(attributes).to include "subject" => ""
      end

      it "assign date with format" do
        attributes = {}
        att = FactoryBot.build_stubbed(:import_assignment, easy_entity_import: subject, entity_attribute: "start_date", format: "%Y/%d/%m")

        subject.ensure_attribute_value(attributes, att, "2018/25/04")
        expect(attributes).to include "start_date" => Date.new(2018, 04, 25)
      end

      it "assign time with format" do
        attributes = {}
        att = FactoryBot.build_stubbed(:import_assignment, easy_entity_import: subject, entity_attribute: "created_on", format: "%Y/%d/%m %H:%M")

        subject.ensure_attribute_value(attributes, att, "2018/25/04 13:33")
        expect(attributes).to include "created_on" => Time.new(2018, 04, 25, 13, 33)
      end
    end

    context "custom field" do
      let(:custom_field_bool) { IssueCustomField.find_by(id: 12) || FactoryBot.create(:issue_custom_field, id: 12, field_format: "bool") }
      let(:custom_field_array) { IssueCustomField.find_by(id: 13) || FactoryBot.create(:issue_custom_field, id: 13, field_format: "list", multiple: true, possible_values: %w[p o p e l k a]) }

      it "import bool CF" do
        attributes = { "custom_fields" => [] }
        att = FactoryBot.build_stubbed(:import_assignment, easy_entity_import: subject, entity_attribute: "cf_#{custom_field_bool.id}")

        subject.ensure_attribute_value(attributes, att, "1")
        expect(attributes["custom_fields"]).to include("id" => "12", "value" => "1")
      end

      it "import multiple" do
        attributes = { "custom_fields" => [] }
        att = FactoryBot.build_stubbed(:import_assignment, easy_entity_import: subject, entity_attribute: "cf_#{custom_field_array.id}")

        subject.ensure_attribute_value(attributes, att, "pop|elka")
        expect(attributes["custom_fields"]).to include("id" => "13", "value" => %w[pop elka])
      end
    end

    context "#ensure_association_value" do

      it "direct id" do
        attributes = {}
        att = FactoryBot.build_stubbed(:import_assignment, easy_entity_import: subject, entity_attribute: "author_id")

        subject.ensure_attribute_value(attributes, att, "1")
        expect(attributes).to include "author_id" => "1"
      end

      it "named" do
        attributes = {}
        att = FactoryBot.build_stubbed(:import_assignment, easy_entity_import: subject, entity_attribute: "priority_id")

        subject.ensure_attribute_value(attributes, att, priority.name.downcase)
        expect(attributes).to include "priority_id" => priority.id
      end

      it "allow_find_by_external_id" do
        attributes = {}
        att = FactoryBot.build_stubbed(:import_assignment, easy_entity_import: subject, entity_attribute: "assigned_to_id", allow_find_by_external_id: true)

        subject.ensure_attribute_value(attributes, att, user.easy_external_id.to_s)
        expect(attributes).to include "assigned_to_id" => user.id
      end

      it "allow_find_by_external_id with default_value" do
        attributes = {}
        att = FactoryBot.build_stubbed(:import_assignment, easy_entity_import: subject, entity_attribute: "author_id", allow_find_by_external_id: true, default_value: user.id)

        subject.ensure_attribute_value(attributes, att, "33")
        expect(attributes).to include "author_id" => user.id.to_s
      end
    end

  end

  describe "#settings" do
    subject { FactoryBot.create(:easy_entity_csv_import) }
    it "is a empty hash" do
      expect(subject.settings).to eq({})
    end

    context "template_id attribute" do

      it "is nil" do
        expect(subject.template_id).to be_nil
      end

      it "is 4" do
        subject.update settings: { template_id: 4 }
        expect(subject.settings).to include(template_id: 4)
        expect(subject.template_id).to eq 4
      end

    end

  end

  describe '#after_save_callback' do
    # let(:template) { FactoryBot.create(:project, easy_is_easy_template: true, easy_start_date: '2018-03-02') }
    let(:project_with_start) { FactoryBot.create(:project, name: 'project_with_start', start_date: '2018-03-22') }
    let(:issue1) { FactoryBot.create(:issue, project: project_with_start, start_date: '2018-04-01', due_date: '2018-05-01') }
    let(:issue2) { FactoryBot.create(:issue, project: project_with_start) }
    let(:project_without_start) { FactoryBot.create(:project, name: 'project_without_start', start_date: nil) }
    let(:issue3) { FactoryBot.create(:issue, project: project_without_start, start_date: '2018-04-01', due_date: '2018-05-01') }
    let(:issue4) { FactoryBot.create(:issue, project: project_without_start) }
    let(:settings) do
      {
        template_id: template.id,
        start_date: '2018-10-01',
        update_dates: '1',
      }
    end

    context 'project with start_date' do
      context 'with update_dates setting' do
        context 'with start_date setting' do
          it 'moves dates' do
            with_easy_settings(project_calculate_start_date: false) do
              issue1; issue2
              settings = {
                template_id: template.id,
                start_date: '2018-10-01',
                update_dates: '1',
              }
              project_import.settings = settings

              project_import.after_save_callback(project_with_start, nil, nil)

              expect(project_with_start.reload.start_date).to eq(Date.new(2018, 3, 22))
              expect(issue1.reload.start_date).to eq(Date.new(2018, 4, 21))
              expect(issue2.reload.start_date).to eq(Date.today + 20)
            end
          end
        end

        context 'without start_date setting' do
          it 'moves dates' do
            with_easy_settings(project_calculate_start_date: false) do
              issue1; issue2
              settings = {
                template_id: template.id,
                update_dates: '1',
              }
              project_import.settings = settings

              project_import.after_save_callback(project_with_start, nil, nil)

              expect(project_with_start.reload.start_date).to eq(Date.new(2018, 3, 22))
              expect(issue1.reload.start_date).to eq(Date.new(2018, 4, 21))
              expect(issue2.reload.start_date).to eq(Date.today + 20)
            end
          end
        end
      end

      context 'with match_starting_dates setting' do
        context 'with start_date setting' do
          it 'matches dates' do
            with_easy_settings(project_calculate_start_date: false) do
              issue1; issue2
              settings = {
                template_id: template.id,
                start_date: '2018-10-01',
                match_starting_dates: '1',
              }
              project_import.settings = settings

              project_import.after_save_callback(project_with_start, nil, nil)

              expect(project_with_start.reload.start_date).to eq(Date.new(2018, 3, 22))
              expect(issue1.reload.start_date).to eq(Date.new(2018, 3, 22))
              expect(issue2.reload.start_date).to eq(Date.new(2018, 3, 22))
            end
          end
        end

        context 'without start_date setting' do
          it 'matches dates' do
            with_easy_settings(project_calculate_start_date: false) do
              issue1; issue2
              settings = {
                template_id: template.id,
                match_starting_dates: '1',
              }
              project_import.settings = settings

              project_import.after_save_callback(project_with_start, nil, nil)

              expect(project_with_start.reload.start_date).to eq(Date.new(2018, 3, 22))
              expect(issue1.reload.start_date).to eq(Date.new(2018, 3, 22))
              expect(issue2.reload.start_date).to eq(Date.new(2018, 3, 22))
            end
          end
        end
      end
    end

    context 'project without start_date' do
      context 'with update_dates setting' do
        context 'with start_date setting' do
          it 'moves dates' do
            with_easy_settings(project_calculate_start_date: false) do
              issue3; issue4
              settings = {
                template_id: template.id,
                start_date: '2018-10-01',
                update_dates: '1',
              }
              project_import.settings = settings

              project_import.after_save_callback(project_without_start, nil, nil)

              expect(project_without_start.reload.start_date).to eq(Date.new(2018, 10, 1))
              expect(issue3.reload.start_date).to eq(Date.new(2018, 10, 31))
              expect(issue4.reload.start_date).to eq(Date.today + 213) # settings[:start_date] - template.start_date = 213
            end
          end
        end

        context 'without start_date setting' do
          it 'moves dates' do
            with_easy_settings(project_calculate_start_date: false) do
              issue3; issue4
              settings = {
                template_id: template.id,
                update_dates: '1',
              }
              project_import.settings = settings

              project_import.after_save_callback(project_without_start, nil, nil)

              expect(project_without_start.reload.start_date).to eq(Date.new(2018, 3, 2))
              expect(issue3.reload.start_date).to eq(Date.new(2018, 4, 1))
              expect(issue4.reload.start_date).to eq(Date.today)
            end
          end
        end
      end

      context 'with match_starting_dates setting' do
        context 'with start_date setting' do
          it 'matches dates' do
            with_easy_settings(project_calculate_start_date: false) do
              issue3; issue4
              settings = {
                template_id: template.id,
                start_date: '2018-10-01',
                match_starting_dates: '1',
              }
              project_import.settings = settings

              project_import.after_save_callback(project_without_start, nil, nil)

              expect(project_without_start.reload.start_date).to eq(Date.new(2018, 10, 1))
              expect(issue3.reload.start_date).to eq(Date.new(2018, 10, 1))
              expect(issue4.reload.start_date).to eq(Date.new(2018, 10, 1))
            end
          end
        end

        context 'without start_date setting' do
          it 'matches dates' do
            with_easy_settings(project_calculate_start_date: false) do
              issue3; issue4
              settings = {
                template_id: template.id,
                match_starting_dates: '1',
              }
              project_import.settings = settings

              project_import.after_save_callback(project_without_start, nil, nil)

              expect(project_without_start.reload.start_date).to eq(Date.new(2018, 3, 2))
              expect(issue3.reload.start_date).to eq(Date.new(2018, 3, 2))
              expect(issue4.reload.start_date).to eq(Date.new(2018, 3, 2))
            end
          end
        end
      end
    end
  end

end
