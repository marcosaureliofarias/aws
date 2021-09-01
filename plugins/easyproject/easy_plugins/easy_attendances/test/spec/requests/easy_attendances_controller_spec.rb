require 'easy_extensions/spec_helper'

describe EasyAttendancesController, logged: :admin, type: :request do

  subject { FactoryBot.create(:easy_attendance) }

  it '#arrival' do
    get arrival_easy_attendances_path, xhr: true
    expect(response).to render_template('easy_attendances/new')
  end

  context 'with easy attendance enabled false' do
    it '#departure' do
      allow_any_instance_of(EasyAttendance).to receive(:save).and_return(false)
      get departure_easy_attendance_path(subject)
      expect(response).to render_template('easy_attendances/edit')
    end
  end

  it '#update' do
    put easy_attendance_path(subject, easy_attendance: { departure: subject.arrival })
    expect(response).to render_template('easy_attendances/edit')
  end

end
