require "easy_extensions/spec_helper"

RSpec.describe EasyActiveJob do
  subject { described_class.new }
  context "#my_logger" do
    let(:logger) { double("Logger") }
    before :each do
      allow(subject).to receive(:my_logger).and_return(logger)
    end
    describe "#log_info" do
      it "log message" do
        expect(logger).to receive(:info).with "Lorem ipsum"
        subject.log_info "Lorem ipsum"
      end
      it "log array" do
        expect(logger).to receive(:info).with "Lorem ipsum\nLorem prdum"
        subject.log_info ["Lorem ipsum", "Lorem prdum"]
      end
    end
    describe "#log_exception" do
      it "log" do
        expect(logger).to receive(:error).with "StandardError: my message"
        expect(logger).to receive(:error).with nil
        ex = StandardError.new("my message")
        subject.log_exception ex
      end
    end
  end
  describe "#my_logger" do
    it "alias error with log file" do
      ex = StandardError.new("my message")
      log = Rails.root.join("log", "easy_active_job.log")
      subject.log_error ex
      expect(File).to exist log
      expect(File.read(log)).to include "ERROR", "my message"
    end
  end
end