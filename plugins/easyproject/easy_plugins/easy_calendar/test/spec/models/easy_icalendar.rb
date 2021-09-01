require 'easy_extensions/spec_helper'

describe EasyIcalendar do

  let(:ical) { FactoryGirl.create(:easy_icalendar) }

  it 'strip url' do
    icl = FactoryGirl.create(:easy_icalendar, url: ' https://url  ')
    expect(icl.url).to match('https://url')
  end

  it 'validation presence of' do
  	ical.to validate_presence_of(:user)
  	ical.to validate_presence_of(:name)
  	ical.to validate_presence_of(:url)
  end
end
