RSpec.describe EasyMonitoring::ApplicationMemory do
  describe "#usage" do
    subject { EasyMonitoring::ApplicationMemory.usage }
    it "unable get data raise exception" do
      expect(described_class).to receive(:usage_by_proc).and_return nil
      expect(described_class).to receive(:usage_by_ps).and_return nil
      expect { subject }.to raise_exception /Unable to get memory/
    end

    describe "#usage_by_ps" do
      before do
        expect(described_class).to receive(:usage_by_proc).and_return nil
      end
      it "macOS ps command" do
        expect(described_class).to receive(:cmd).and_return "ps: rsz: keyword not found\nps: no valid keywords; valid keywords\ncpu %mem acflag acflg..."
        expect { subject }.to raise_exception /Unable to get memory/
      end
      it "Debian ps command" do
        expect(described_class).to receive(:cmd).and_return "  RSZ\n18940\n"
        is_expected.to eq 18.50
      end
      it "in cloud it must works without mock" do
        skip "Test only for easy cloud" unless `hostname`.end_with? "easy2.cloud"
        is_expected.to be > 0
      end
    end
    describe "#usage_by_proc" do
      before do
        allow(described_class).to receive(:usage_by_ps).and_return nil
      end
      it "proc_file doesnt exists" do
        expect(described_class).to receive(:proc_status_file).and_return("/tmp/this-file-doest-exists-#{Date.today.to_s}").twice
        expect { subject }.to raise_exception /Unable to get memory/
      end
      it "correct proc_file" do
        expect(described_class).to receive(:proc_status_file).and_return(File.expand_path(File.join(__dir__, "../", "fixtures/files", "proc_pid_status"))).twice
        is_expected.to eq 295.05
      end
      it "in cloud it must works without mock" do
        skip "Test only for easy cloud" unless `hostname`.end_with? "easy2.cloud"
        is_expected.to be > 0
      end
    end
  end
end