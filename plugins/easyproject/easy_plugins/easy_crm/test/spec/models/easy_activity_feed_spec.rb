require 'easy_extensions/spec_helper'

describe 'Easy activity feed' do

  it 'should have easy_activity_provider_options on EasyCrmCase' do
    expect(EasyCrmCase.activity_provider_options[:easy_activity_options]['easy_crm_cases']).not_to eq(nil)
  end

end
