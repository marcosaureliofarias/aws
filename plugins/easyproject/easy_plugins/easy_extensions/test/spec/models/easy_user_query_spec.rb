require 'easy_extensions/spec_helper'

describe 'EasyUserQuery', logged: :admin do
  let(:user) { FactoryBot.create(:user) }
  let(:user_with_tag) { FactoryBot.create(:user, tag_list: ['IT']) }

  it 'filter tags' do
    user; user_with_tag
    q = EasyUserQuery.new(name: '_')
    q.from_params('set_filter' => '1', 'tags' => 'IT')
    expect(q.entity_count).to eq(1)
    expect(q.entities).to eq([user_with_tag])
  end
end
