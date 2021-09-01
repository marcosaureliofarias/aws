require 'easy_extensions/spec_helper'

RSpec.describe EasyExtensions::EasyProjectSettings do
  context 'available_event_types' do
    it 'should be without types from disabled features' do
      described_class.disabled_features[:modules].each do |disabled_feature|
        expect(described_class.available_event_types).not_to include(disabled_feature)
      end
    end
  end
end
