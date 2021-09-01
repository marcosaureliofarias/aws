RSpec.describe EasyCalendar::IcalendarImportService do

  let(:ical) { FactoryGirl.create(:easy_icalendar) }

  file = File.open(File.join(File.dirname(__FILE__) + '/../../fixtures', 'two_time_events.ics'))
  subject(:import) { described_class.call(ical) }
  
  before do
    allow(ical).to receive(:url).and_return(file)
  end

  it 'success' do
    expect(import.success?).to be_truthy
  end

  it 'synchronized_at' do
    expect(import.calendar.synchronized_at).not_to be_nil
  end

  it 'events' do
    expect(import.calendar.events).not_to be_empty
  end

  it 'failed: ical is nil' do
    allow_any_instance_of(EasyIcalHelper).to receive(:load_icalendar).and_return(nil)
    expect(import.failed?).to be_truthy
    expect(import.calendar.message).to eq(I18n.t(:notice_ical_import_events_failed))
    expect(import.calendar.events).to be_empty
  end

  it 'failed: import error' do
    allow_any_instance_of(EasyIcalHelper).to receive(:load_icalendar).and_raise(Timeout::Error)
    expect(import.failed?).to be_truthy
    expect(import.calendar.message).to eq('Timeout::Error')
    expect(import.calendar.events).to be_empty
  end

end
