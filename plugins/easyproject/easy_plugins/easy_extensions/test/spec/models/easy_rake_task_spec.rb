require 'easy_extensions/spec_helper'

describe EasyRakeTask do

  context 'execution is enabled / disabled' do

    let(:rake_task) { FactoryBot.create(:easy_rake_task_active) }
    let(:rake_task_info) { FactoryBot.create(:easy_rake_task_info, easy_rake_task: rake_task) }

    context 'enabled' do
      before(:each) do
        allow(EasyRakeTask).to receive(:execution_disabled?).and_return(false)
      end

      it 'execute_classes' do
        rake_task
        expect_any_instance_of(EasyRakeTask).to receive(:execute).and_return(nil)
        EasyRakeTask.execute_classes('EasyRakeTask')
      end

      it 'execute_tasks / enabled' do
        rake_task
        expect_any_instance_of(EasyRakeTask).to receive(:execute).and_return(nil)
        EasyRakeTask.execute_tasks(EasyRakeTask.active)
      end

      it 'execute_scheduled / enabled' do
        rake_task
        expect_any_instance_of(EasyRakeTask).to receive(:execute).and_return(nil)
        EasyRakeTask.execute_scheduled
      end

      it 'execute_task / enabled' do
        expect_any_instance_of(EasyRakeTask).to receive(:execute).and_return(nil)
        EasyRakeTask.execute_task rake_task
      end

      it 'execute_task_with_current_info / enabled' do
        expect_any_instance_of(EasyRakeTask).to receive(:execute).and_return(nil)
        EasyRakeTask.execute_task_with_current_info rake_task, rake_task_info
      end
    end

    context 'disabled' do
      before do
        allow(EasyRakeTask).to receive(:execution_disabled?).and_return(true)
        expect_any_instance_of(EasyRakeTask).not_to receive(:execute)
      end

      it 'execute_classes' do
        rake_task
        expect_any_instance_of(EasyRakeTask).not_to receive(:execute).and_return(nil)
        EasyRakeTask.execute_classes('EasyRakeTask')
      end

      it 'execute_tasks / enabled' do
        rake_task
        expect_any_instance_of(EasyRakeTask).not_to receive(:execute).and_return(nil)
        EasyRakeTask.execute_tasks(EasyRakeTask.active)
      end

      it 'execute_scheduled / enabled' do
        rake_task
        expect_any_instance_of(EasyRakeTask).not_to receive(:execute).and_return(nil)
        EasyRakeTask.execute_scheduled
      end

      it 'execute_task / enabled' do
        expect_any_instance_of(EasyRakeTask).not_to receive(:execute).and_return(nil)
        EasyRakeTask.execute_task rake_task
      end

      it 'execute_task_with_current_info / enabled' do
        expect_any_instance_of(EasyRakeTask).not_to receive(:execute).and_return(nil)
        EasyRakeTask.execute_task_with_current_info rake_task, rake_task_info
      end
    end

  end

end
