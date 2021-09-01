require_relative '../spec_helper'

describe 'EasyCrmCaseItemQuery', :logged => :admin do
  it 'distinct columns' do
    query = EasyCrmCaseItemQuery.new
    column = query.get_column('easy_crm_cases.price')
    expect(query.entity_sum(column)).to be_zero
  end
end
