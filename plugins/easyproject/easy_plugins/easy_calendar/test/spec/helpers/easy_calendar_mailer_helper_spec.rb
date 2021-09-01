require 'easy_extensions/spec_helper'

describe EasyCalendarMailerHelper, logged: :admin do
  let!(:meeting) { FactoryBot.create(:easy_meeting, start_time: { 'date' => User.current.today, 'time' => '11:30' },  end_time: { 'date' => User.current.today, 'time' => '12:30' }) }
  let!(:project) { FactoryBot.create(:project) }

  it 'meeting invitation is standard subject' do
    expect(helper.invitation_subject(meeting)).to eq(I18n.t(:title_meeting_invitation))
  end

  it 'meeting invitation is a subject with info about update when meeting was updated' do
    meeting.emailed = true
    expect(helper.invitation_subject(meeting)).to eq(I18n.t(:title_meeting_invitation_updated, name: meeting.name))
  end

  it 'meeting invitation subject contains info about project if project is selected' do
    meeting.update(project: project)
    expect(helper.invitation_subject(meeting.reload)).to eq("#{ meeting.reload.project.name}: #{I18n.t(:title_meeting_invitation)}")
  end

  it 'meeting invitation subject contains info about project and note that it is just update when meeting was updated' do
    meeting.update(project: project)
    meeting.emailed = true
    expect(helper.invitation_subject(meeting)).to eq(I18n.t(:title_meeting_project_invitation_updated, project: meeting.project.name, name: meeting.name))
  end
end
