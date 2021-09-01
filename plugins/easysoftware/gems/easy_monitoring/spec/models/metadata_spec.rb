RSpec.describe EasyMonitoring::Metadata do
  describe "#host_name" do
    subject { described_class.instance.host_name }
    it "default" do
      described_class.remove_class_variable :"@@instance" if described_class.class_variable_defined? :"@@instance"
      is_expected.to be_nil
    end
    it "with configured" do
      described_class.configure { |m| m.host_name = "xyz" }
      is_expected.to eq "xyz"
    end
  end
end