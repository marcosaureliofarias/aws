require 'easy_extensions/spec_helper'

describe EasyEntityImports::XlsxSimpleImporter, logged: :admin do

  let(:importer) { EasyEntityImports::XlsxSimpleImporter.new }

  let(:rows) do
    file = Rails.root.join('plugins/easyproject/easy_plugins/easy_extensions/test/fixtures/files/easy_entity_imports/excel_sample_import_file_cs.xlsx').to_s
    importer.send(:parse_file, file)
  end

  context 'initialize' do
    it 'should init logger' do
      expect(importer.logger.class).to be EasyEntityImports::ImportLogger
    end
  end

  context 'default_value_for' do
    it 'should get default data' do
      expect(importer.send(:default_value_for, :tracker).class).to be Tracker
      expect(importer.send(:default_value_for, :priority).class).to be IssuePriority
      expect(importer.send(:default_value_for, :status).class).to be IssueStatus
    end
  end

  it 'should import all data successfully EN' do
    FactoryGirl.create :user, firstname: 'Importer', lastname: 'Doe'
    file = Rails.root.join('plugins/easyproject/easy_plugins/easy_extensions/test/fixtures/files/easy_entity_imports/excel_sample_import_file_en.xlsx').to_s
    expect(importer.import(file)).to be_truthy
    issues = Issue.order(:id)

    # projects
    expect(importer.log[:projects][:created].values.map(&:name)).to eq ['Project 1', 'Project 2']
    expect(issues.map(&:project_id).uniq).to match_array importer.log[:projects][:created].values.map(&:id)

    # issues
    expect(issues.map(&:subject)).to match_array ['Task #1', 'Task #2', 'Task #3', 'Task #4', 'Task #1', 'Task #2', 'Task #3', 'Task #4']

    # due dates
    expect(issues[0..-2].map(&:due_date).uniq).to eq [Date.parse('24/12/2017'), Date.parse('25/12/2017')]
    expect(issues.last.due_date).to be nil
    expect(importer.log[:issues][:warnings][issues.last.id]).to satisfy { |warnings| warnings.detect { |w| w.include?(I18n.t('activerecord.errors.messages.not_a_date')) } }

    # assignees
    expect(issues.first.assigned_to_id).to be User.last.id
    expect(issues[1..-1].map(&:assigned_to_id).compact).to eq []
    expect(importer.log[:issues][:warnings].keys).to match_array issues[1..-1].map(&:id)
    expect(importer.log[:issues][:warnings][issues.last.id]).to satisfy { |warnings| warnings.detect { |w| w.include?("#{I18n.t('easy_imports.could_not_find_user', user_name: 'Neo Anderson')} #{I18n.t('easy_imports.assignee_set_to_nobody')}") } }

    # issue priorities
    expect(importer.log[:issue_priorities][:created].values.map(&:name)).to eq ['priority #1', 'priority #2', 'priority #3']
    expect(issues.map(&:priority_id).uniq).to match_array importer.log[:issue_priorities][:created].values.map(&:id)

    # issue statuses
    expect(importer.log[:issue_statuses][:created].values.map(&:name)).to eq ['new', 'in progress']
    expect(issues.map(&:status_id).uniq).to match_array importer.log[:issue_statuses][:created].values.map(&:id)

    # trackers
    expect(importer.log[:trackers][:created].values.map(&:name)).to eq ['task', 'bug']
    expect(issues.map(&:tracker_id).uniq).to match_array importer.log[:trackers][:created].values.map(&:id)

    # description
    expect(issues.first.description).to eq 'long text'

    # parent tasks
    expect(issues[1].parent_id).to eq issues[0].id
    expect(issues[2].parent_id).to eq issues[1].id
    expect(issues[5].parent_id).to eq issues[4].id
    expect(importer.log[:issues][:warnings][issues.last.id]).to satisfy { |warnings| warnings.detect { |w| w.include?("#{I18n.t('easy_imports.could_not_find_task', entity_name: 'Not existing task')} #{I18n.t('easy_imports.parent_task_was_not_set')}") } }
  end

  context 'import' do
    it 'should import all data successfully CS' do
      FactoryGirl.create :user, firstname: 'Importer', lastname: 'Doe'
      file = Rails.root.join('plugins/easyproject/easy_plugins/easy_extensions/test/fixtures/files/easy_entity_imports/excel_sample_import_file_cs.xlsx').to_s
      expect(importer.import(file)).to eq true
      issues = Issue.order(:id)

      # projects
      expect(importer.log[:projects][:created].values.map(&:name)).to eq ['Projekt 1', 'Projekt 2']
      expect(issues.map(&:project_id).uniq).to match_array importer.log[:projects][:created].values.map(&:id)

      # issues
      expect(issues.map(&:subject)).to match_array ['Úkol 1', 'Úkol 2', 'Úkol 3', 'Úkol 4', 'Úkol 1', 'Úkol 2', 'Úkol 3', 'Úkol 4']

      # due dates
      expect(issues[0..-2].map(&:due_date).uniq).to eq [Date.parse('24/12/2017'), Date.parse('25/12/2017')]
      expect(issues.last.due_date).to be nil
      expect(importer.log[:issues][:warnings][issues.last.id]).to satisfy { |warnings| warnings.detect { |w| w.include?(I18n.t('activerecord.errors.messages.not_a_date')) } }

      # assignees
      expect(issues.first.assigned_to_id).to be User.last.id
      expect(issues[1..-1].map(&:assigned_to_id).compact).to eq []
      expect(importer.log[:issues][:warnings].keys).to match_array issues[1..-1].map(&:id)
      expect(importer.log[:issues][:warnings][issues.last.id]).to satisfy { |warnings| warnings.detect { |w| w.include?("#{I18n.t('easy_imports.could_not_find_user', user_name: 'Honza Novotny')} #{I18n.t('easy_imports.assignee_set_to_nobody')}") } }

      # issue priorities
      expect(importer.log[:issue_priorities][:created].values.map(&:name)).to eq ['Priority 1', 'Priority 2', 'Priority 3']
      expect(issues.map(&:priority_id).uniq).to match_array importer.log[:issue_priorities][:created].values.map(&:id)

      # issue statuses
      expect(importer.log[:issue_statuses][:created].values.map(&:name)).to eq ['nový', 'v realizaci']
      expect(issues.map(&:status_id).uniq).to match_array importer.log[:issue_statuses][:created].values.map(&:id)

      # trackers
      expect(importer.log[:trackers][:created].values.map(&:name)).to eq ['Úkol', 'Programování']
      expect(issues.map(&:tracker_id).uniq).to match_array importer.log[:trackers][:created].values.map(&:id)

      # description
      expect(issues.first.description).to eq 'dlouhý text'

      # parent tasks
      expect(issues[1].parent_id).to eq issues[0].id
      expect(issues[2].parent_id).to eq issues[1].id
      expect(issues[5].parent_id).to eq issues[4].id
      expect(importer.log[:issues][:warnings][issues.last.id]).to satisfy { |warnings| warnings.detect { |w| w.include?("#{I18n.t('easy_imports.could_not_find_task', entity_name: 'Not existing task')} #{I18n.t('easy_imports.parent_task_was_not_set')}") } }
    end

    it 'should import with default data' do
      file   = Rails.root.join('plugins/easyproject/easy_plugins/easy_extensions/test/fixtures/files/easy_entity_imports/excel_sample_import_file_en_only_required_columns.xlsx').to_s
      issues = Issue.all

      expect(importer.import(file)).to be_truthy
      expect(issues.size).to be 8
      expect(issues.map(&:tracker_id)).not_to include(nil)
      expect(issues.map(&:status_id)).not_to include(nil)
      expect(issues.map(&:priority_id)).not_to include(nil)
    end

    it 'should contain error message file could not be processed' do
      expect(importer.import(nil)).to be_falsey
      expect(importer.log[:fatal_error]).to include(I18n.t('easy_imports.file_could_not_be_processed'))
    end

    it 'should contain error message with missing column names' do
      file = Rails.root.join('plugins/easyproject/easy_plugins/easy_extensions/test/fixtures/files/easy_entity_imports/excel_sample_import_file_empty.xlsx').to_s

      expect(importer.import(file)).to be_falsey
      expect(importer.log[:fatal_error]).to include(I18n.t(:label_project), I18n.t(:label_issue))
    end
  end

end
