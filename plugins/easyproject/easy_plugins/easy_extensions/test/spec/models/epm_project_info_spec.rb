require 'easy_extensions/spec_helper'

describe 'epm project info', :logged => :admin do
  it 'without project' do
    data = EpmProjectInfo.new.get_edit_data({}, User.current)
    expect(data).to be_a(Hash)
    expect(data.keys).to include(:groups, :select_options)
    expect(data[:groups]).to match_array('all')
  end
end
