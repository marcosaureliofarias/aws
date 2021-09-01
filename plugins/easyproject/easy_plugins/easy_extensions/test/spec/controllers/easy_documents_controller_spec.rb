require 'easy_extensions/spec_helper'

describe EasyDocumentsController, :logged => :admin do
  render_views

  it 'index' do
    get :index
    expect(response).to be_successful
  end

end
