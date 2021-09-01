require_relative './shared_stuff.rb'

RSpec.describe EasyXmlData::Exporter, type: :model do
  let(:project) { FactoryGirl.create(:project) }
  let(:exporter) { EasyXmlData::Exporter.new(EasyXmlData::Exporter.exportables, project.id) }

  it_behaves_like 'exporter object' do
    let(:expected_exported_elements) { %w(issue project tracker issue-priority issue-status time-entry-activity project-activity) }
  end
end
