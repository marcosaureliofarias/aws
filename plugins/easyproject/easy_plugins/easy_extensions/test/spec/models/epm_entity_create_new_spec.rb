require 'easy_extensions/spec_helper'

describe EpmEntityCreateNew, logged: :admin do
  it 'principals' do
    mod = EpmEntityCreateNew.new
    expect(mod.all_principals).to match_array([User.current])
  end
end
