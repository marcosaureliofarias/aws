require 'easy_extensions/spec_helper'

describe EasyQuerySettingsController, logged: :admin do
  it 'saves default outputs' do
    put :save, params: { tab: 'easy_issue_query', easy_query: {outputs: ['list', 'chart']} }
    expect(response).to be_successful
    expect(EasyIssueQuery.new.send(:get_default_values_from_easy_settings, 'default_outputs')).to match_array(['list', 'chart'])
  end
end
