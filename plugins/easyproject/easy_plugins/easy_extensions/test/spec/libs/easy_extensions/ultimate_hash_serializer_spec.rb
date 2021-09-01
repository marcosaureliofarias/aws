RSpec.describe EasyExtensions::UltimateHashSerializer do

  let(:data) { { 'test' => 1 } }
  let(:serialized_data) { YAML.dump(data) }
  let(:serialized_indifferent_data) { YAML.dump(data.with_indifferent_access) }

  context '#dump' do

    it 'NilClass' do
      expect(described_class.dump(nil)).to be_nil
    end

    it 'Hash' do
      expect(described_class.dump(data)).to eq(serialized_data)
    end

    it 'ActionController::Parameters' do
      expect(described_class.dump(ActionController::Parameters.new(data))).to eq(serialized_indifferent_data)
    end

    it 'something else' do
      expect { described_class.dump('test') }.to raise_error(ActiveRecord::SerializationTypeMismatch)
    end

  end

  context '#load' do

    it 'NilClass' do
      expect(described_class.load(nil)).to eq({})
    end

    it 'Hash' do
      expect(described_class.load(serialized_data)).to eq(data)
    end

    it 'ActionController::Parameters' do
      expect(described_class.load(serialized_indifferent_data)).to eq(data)
    end

    it 'something else' do
      expect(described_class.load('test')).to eq('test')
    end

    it 'serialized something else' do
      expect { described_class.load(YAML.dump('test')) }.to raise_error(ActiveRecord::SerializationTypeMismatch)
    end

  end

end
