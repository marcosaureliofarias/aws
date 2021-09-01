require 'easy_extensions/spec_helper'

RSpec.describe EpmScheduler, type: :model, logged: :admin do
  it 'show data with selected principals' do
    res = EpmScheduler.new.get_show_data({'query_settings' => {'settings' => {'selected_principal_ids' => ['', User.current.id.to_s]}}}, User.current, {})
    expect(res.has_key?(:query)).to eq(true)
  end
end
