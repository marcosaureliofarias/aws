RSpec.describe EasySwagger::Blocks::SchemaNode do
  let(:opts) { {} }
  let(:node) do
    i = described_class.new
    i.keys opts
    i
  end
  subject { node }

  describe "#api_response?" do
    subject { node.api_response? }
    context "when no name" do
      it "should be false" do
        is_expected.to be_falsey
      end
    end

    context "when name is Request" do
      let(:node) do
        i = described_class.new
        i.schema_name = "IssueApiRequest"
        i
      end
      it "should be false" do
        is_expected.to be_falsey
      end
    end
    context "when name is Response" do
      let(:node) do
        i = described_class.new
        i.schema_name = "IssueApiResponse"
        i
      end
      it "should be true" do
        is_expected.to be_truthy
      end
    end
  end

  describe "#relation" do
    context "with nil" do
      it "should do nothing" do
        expect(subject).not_to receive(:property)
        subject.relation
      end
    end
    context "with one argument" do
      it "should receive 1 property" do
        expect(subject).to receive(:property).once.with("user_id", {})
        subject.relation "user"
      end
    end
    context "with three arguments" do
      it "should receive 3 property" do
        expect(subject).to receive(:property).exactly(3).times
        subject.relation "user", "issue", "project"
      end
    end
    context "with argument in Response" do
      let(:node) do
        i = described_class.new
        i.schema_name = "TimeEntryApiResponse"
        i
      end
      it "should register property without suffix _id" do
        allow(subject).to receive(:api_response?).and_return false
        expect(subject).to receive(:property).once.with("user_id", {})
        subject.relation "user"
      end
      it "raise exception if you use relation wrong" do
        expect(subject).not_to receive(:property)
        expect { subject.relation "user_id" }.to raise_exception ArgumentError
      end
    end

    context "with inline_keys for :if" do
      it "should apply condition" do
        expect(subject).to receive(:property).exactly(2).times
        subject.relation "user", "issue", if: ->(object) { object.admin? }
      end
    end
  end
end