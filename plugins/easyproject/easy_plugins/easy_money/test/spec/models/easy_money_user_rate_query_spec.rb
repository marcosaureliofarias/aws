require 'easy_extensions/spec_helper'

describe 'easy money user rate query', logged: :admin do
  let(:easy_money_rate) { FactoryBot.create(:easy_money_rate) }

  it 'values' do
    easy_money_rate
    q = EasyMoneyUserRateQuery.new
    allow(q).to receive(:available_rate_types).and_return([easy_money_rate.rate_type])
    user = q.entities.detect{|u| u.id == easy_money_rate.entity_id}
    expect(user).not_to eq(nil)
    colname = "rate_type_#{easy_money_rate.rate_type.id}_unit_rate".to_sym
    expect(q.available_columns.map(&:name)).to include(colname)
    expect(user.send(colname)).to eq(easy_money_rate.unit_rate)
  end
end
