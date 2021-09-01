require 'easy_extensions/spec_helper'

RSpec.describe Date do

  context '.safe_parse' do

    let(:invalid_inputs) { [nil, false, 'hello'] }
    let(:valid_inputs) { ['2019-01-01T15:06:35+01:00', '2019/01/01'] }

    it 'can safely parse non-dates' do
      invalid_inputs.each do |input|
        expect(described_class.safe_parse(input)).to eq(nil)
      end
    end

    it 'parses string dates' do
      valid_inputs.each do |input|
        expect(described_class.safe_parse(input)).to eq(Date.new(2019, 1, 1))
      end
    end

  end

end
