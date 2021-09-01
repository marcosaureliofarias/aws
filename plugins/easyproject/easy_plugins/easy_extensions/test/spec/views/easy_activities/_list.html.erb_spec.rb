require 'easy_extensions/spec_helper'


describe 'easy_activities/_list', logged: :admin do

  helper :activities, :avatars

  let(:event) { FactoryGirl.create(:issue) }

  it 'render partial' do
    assign(:events, [event])
    assign(:events_by_day, { Time.now => [event] })
    render
    expect(rendered).to match event.subject
  end

end
