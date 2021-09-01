require 'easy_extensions/spec_helper'

describe EasyAgileBoardQuery, type: :model, logged: :admin do
  let(:query) { FactoryGirl.create(:easy_agile_board_query, is_tagged: false) }

  it 'forces is_tagged to true' do
    expect(query.is_tagged).to eq(true)
  end
end
