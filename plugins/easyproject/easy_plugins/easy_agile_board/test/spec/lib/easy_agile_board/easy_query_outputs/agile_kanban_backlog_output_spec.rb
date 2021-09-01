require 'easy_extensions/spec_helper'

describe EasyAgileBoard::EasyQueryOutputs::AgileKanbanBacklogOutput do
  let(:project) { double(id: 42) }
  let(:query) { double(outputs: [], project: project) }
  let(:agile_kanban_backlog_output) { described_class.new(query) }

  describe '#possible_phases' do
    context 'without edit permission', logged: true do
      before(:each) do
        role = Role.non_member
        role.add_permission! :view_easy_kanban_board
      end

      it 'does not allow issue dropping' do
        expect(agile_kanban_backlog_output.possible_phases(nil)).to eq([])
      end
    end

  end

end
