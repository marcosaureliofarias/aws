require 'easy_extensions/spec_helper'

describe EasyQueryManagementController, :logged => :admin do
  render_views

  it 'edit' do
    get :edit, :params => { :type => 'EasyIssueQuery' }
    expect(response).to be_successful
  end

end
