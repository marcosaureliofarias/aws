require 'easy_extensions/spec_helper'

describe EasyAgileBoard::EasyQueryOutputs::AgileKanbanOutput do
  let(:project) { double(id: 42) }
  let(:easy_sprint) { double(capacity_attribute: 'story points', project: project) }
  let(:query) { double(easy_sprint: easy_sprint, outputs: [], project: project) }
  let(:agile_kanban_output) { described_class.new(query) }
  let(:scrum_output_setting) do
    { 'main_attribute' => 'project',
      'summable_column' => 'easy_story_points',
      'avatar_attribute' => 'assigned_to' }
  end

  describe 'kanban output_settings' do
    before(:each) do
      allow(EasySetting).to receive(:value).with('kanban_output_setting', project).and_return(saved_settings)
    end

    context 'saved as ActionController::Parameters' do
      let(:saved_settings) { ActionController::Parameters.new(scrum_output_setting) }

      it 'return Hash with saved values' do
        expect(agile_kanban_output.kanban_output_settings).to include(scrum_output_setting)
      end
    end

    context 'saved as Hash' do
      let(:saved_settings) { scrum_output_setting.dup }

      it 'returns Hash with saved values' do
        expect(agile_kanban_output.kanban_output_settings).to include(scrum_output_setting)
      end
    end
  end

end
