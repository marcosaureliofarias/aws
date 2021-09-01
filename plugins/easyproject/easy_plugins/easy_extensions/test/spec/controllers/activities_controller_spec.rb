require 'easy_extensions/spec_helper'

describe ActivitiesController, :logged => :admin do
  render_views

  it 'should select active project by default' do
    get :index
    expect(response).to be_successful
  end
end
