require_relative '../spec_helper'

RSpec.describe EasyIssueQuery, type: :model, logged: :admin do
  it 'replace me' do
    expect(described_class.new.send(:personalized_field_value_for_statement, 'assigned_to_id_supervisor', 'me')).to eq(User.current.id.to_s)
  end
end
