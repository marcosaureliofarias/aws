require 'easy_extensions/spec_helper'

describe CalendarsController, :logged => :admin do

  context 'issue calendar' do
    render_views

    it 'show' do
      get :show
      expect(response).to be_successful
    end
  end

end
