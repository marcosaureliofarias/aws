require 'easy_extensions/spec_helper'

RSpec.describe EasyExtensions::EasyQueryHelpers::ValuesValidator do
  subject { described_class.new(EasyIssueQuery.new) }

  VALID_ITEMS = [
      {
          field: 'done_ratio', # integer
          values: ['0', '-1', '-500000', '98987954']
      },
      {
          field: 'status_id', # list_status
          values: ['1', '222222222']
      }
  ]

  INVALID_ITEMS = [
      {
          field: 'done_ratio', # integer
          values: ['', 'aaa', 'a a a ', '1 2 3 4 5 6']
      },
      {
          field: 'status_id', # list_status
          values: ['', 'aaaa', 'aaa aaa', '-445', '1.5']
      }
  ]

  it 'VALID #valid?' do
    VALID_ITEMS.each do |item|
      expect(subject.valid?(item[:field], '=', item[:values])).to be_truthy
    end
  end

  it 'INVALID #valid?' do
    INVALID_ITEMS.each do |item|
      expect(subject.valid?(item[:field], '=', item[:values])).to be_falsey
    end
  end

end
