require 'easy_extensions/spec_helper'

describe TrackersController, logged: :admin do
  let(:tracker) { FactoryBot.create(:tracker) }
  let(:tracker_to_override) { FactoryBot.create(:tracker) }

  context '#update action' do
    it 'just update if override workflow param is blank' do
      put :update, params: { id: tracker.id, tracker: { easy_icon: 'icon-remove' } }
      expect(tracker.reload.easy_icon).to eq('icon-remove')
    end

    it 'update current workflow if param override workflow is not blank' do
      tracker_to_override
      put :update, params: { id: tracker.id, tracker: { override_workflow_by: tracker_to_override.id } }
      expect(tracker.workflow_rules.include?(tracker_to_override.id))
    end
  end
end
