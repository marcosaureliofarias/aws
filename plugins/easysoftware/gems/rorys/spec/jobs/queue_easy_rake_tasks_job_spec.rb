RSpec.describe Rorys::QueueEasyRakeTasksJob do
  describe "#perform" do
    let(:task) { spy("EasyRakeTask", id: 1) }
    before :each do
      allow(EasyRakeTask).to receive(:scheduled).and_return [task]
    end

    it "queue single task", pending: true do
      expect(task).to receive(:update_column).with(:blocked_at, kind_of(Time))
      expect {
        described_class.perform_now
      }.to have_enqueued_job(Rorys::EasyRakeTaskJob).with "RSpec::Mocks::Double", 1
    end
  end
end