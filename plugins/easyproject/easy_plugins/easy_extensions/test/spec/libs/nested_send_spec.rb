require 'easy_extensions/spec_helper'

describe 'nested send', :null => true do
  it 'should return a value' do
    expect([1, 2, 3].nested_send('first')).to eq 1
  end

  it 'should return a nested value' do
    expect([1, 2, 3].nested_send('to_a.first')).to eq 1
  end

  it 'should support params' do
    expect([1, 2, 3].nested_send('to_a.first', 2)).to eq [1, 2]
  end

  it 'should return nil if any of values is a nil' do
    expect([nil, 2, 3].nested_send('first.last')).to eq nil
  end
end
