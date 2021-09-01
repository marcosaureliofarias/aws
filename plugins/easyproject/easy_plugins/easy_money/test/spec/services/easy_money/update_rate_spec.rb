require 'easy_extensions/spec_helper'

describe EasyMoney::UpdateRate, without_cache: true do
  let(:easy_currency) { FactoryBot.create :easy_currency, :czk, is_default: true }
  let(:project) { FactoryBot.create :project, number_of_issues: 0, number_of_subprojects: 0, number_of_issue_categories: 0, easy_currency: easy_currency}

  let(:global_user_rate) { FactoryBot.create :easy_money_rate, easy_currency: easy_currency}
  let(:project_user_rate) { FactoryBot.create :easy_money_rate, easy_currency: easy_currency, entity: global_user_rate.entity, rate_type: global_user_rate.rate_type, project: project }

  let(:user) { global_user_rate.entity }

  it 'update with the new attributes' do
    easy_money_rate = described_class.call(project_user_rate, {unit_rate: 5000})
    expect(easy_money_rate.errors).to be_empty
    expect(easy_money_rate).to be_persisted
    expect(easy_money_rate).to have_attributes(unit_rate: 5000)
  end

  it 'update with invalid attributes' do
    easy_money_rate = described_class.call(project_user_rate, {unit_rate: -100})
    expect(easy_money_rate.errors).not_to be_empty
  end

  it 'should remove project rate and return global rate' do
    easy_money_rate = described_class.call(project_user_rate, {unit_rate: ''})
    expect(easy_money_rate).to eq(global_user_rate)
  end

  it 'should remove global rate and return new rate' do
    easy_money_rate = described_class.call(global_user_rate, {unit_rate: ''})
    expect(easy_money_rate).to be_new_record
    expect(easy_money_rate).to have_attributes(easy_currency: easy_currency, entity: user)
  end

end
