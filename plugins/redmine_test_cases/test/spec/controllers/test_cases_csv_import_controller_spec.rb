require File.expand_path('../../spec_helper.rb', __FILE__)
require_relative '_test_cases_csv_import_controller_requests'

describe TestCasesCsvImportController do
  let(:project) { FactoryBot.create(:project, :add_modules => %w(test_cases)) }

  tc_type =EasyTestCaseCsvImport
  entity_type = 'TestCase'
  other_type = EasyEntityCsvImport
  other_entity_type = 'EasyContactGroup'


  describe 'user (anonym) without import_test_cases permsission' do
    it_should_behave_like :test_cases_csv_import_controller_requests, tc_type, entity_type, false
  end

  describe 'admin user with test case entity', logged: :admin do
    it_should_behave_like :test_cases_csv_import_controller_requests, tc_type, entity_type, true
  end

  describe 'logged user with persmission', logged: true do
    let!(:role) { FactoryBot.create(:role) }
    let!(:user) { FactoryBot.create(:user) }
    let!(:member) { FactoryBot.create(:member, project: project, user: user, roles: [role]) }

    before :each do
      role.add_permission! :import_test_cases
      role.reload
      project.reload
      user.reload
      allow(User).to receive(:current).and_return(user)
    end

    it_should_behave_like :test_cases_csv_import_controller_requests, tc_type, entity_type, true
  end

  describe 'logged user without persmission', logged: true do
    let(:role) { FactoryBot.create(:role) }
    let(:user) { FactoryBot.create(:user) }
    let(:member) { FactoryBot.create(:member, project: project, user: user, roles: [role]) }

    before :each do
      allow(User).to receive(:current).and_return(user)
    end

    it_should_behave_like :test_cases_csv_import_controller_requests, tc_type, entity_type, false
  end

end
