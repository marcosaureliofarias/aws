require_relative '../../../spec_helper'

RSpec.describe EasyJenkins::Api::Connection do
  describe 'parse_json' do
    let(:json_string) { { json: '' }.to_json }

    subject { described_class.new.parse_json(json_string) }

    it do
      expect(subject).to eq({ "json" => "" })
    end
  end
end