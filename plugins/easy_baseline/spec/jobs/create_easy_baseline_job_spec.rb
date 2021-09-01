require File.expand_path('../../../../easyproject/easy_plugins/easy_extensions/test/spec/spec_helper', __FILE__)

RSpec.describe CreateEasyBaselineJob, logged: :admin, type: :job do
  let!(:project) { FactoryBot.create(:project, name: 'My project', add_modules: %w(easy_baselines easy_gantt)) }

  context 'create baseline from project' do
    it 'create baseline with title' do
      options = { title: 'My baseline' }
      expect {
        described_class.perform_now(project, User.current, options)
      }.to change(Project, :count).by(2)
    end
  end

  context 'create baseline from project with subproject' do
    let!(:subproject) { FactoryBot.create(:project, name: 'My project', parent: project, add_modules: %w(easy_baselines easy_gantt)) }

    it 'create baseline with subproject' do
      options = { title: 'My baseline' }
      expect {
        described_class.perform_now(project, User.current, options)
      }.to change(Project, :count).by(2)
    end
  end
end