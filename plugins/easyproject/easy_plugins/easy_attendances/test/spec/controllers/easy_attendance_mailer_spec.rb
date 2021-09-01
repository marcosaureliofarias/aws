require 'easy_extensions/spec_helper'

include EasyAttendancesHelper

describe EasyAttendancesController, logged: :admin do
  let(:approval_activity)     { FactoryGirl.create(:vacation_easy_attendance_activity, :mail => 'test@test.cz') }
  let(:non_approval_activity) { FactoryGirl.create(:vacation_easy_attendance_activity, :approval_required => false, :mail => 'test@test.cz') }
  let(:approval_attendance_params) {
    attributes = FactoryGirl.attributes_for(:full_day_easy_attendance)
    attributes[:user_id] = User.current.id
    attributes[:easy_attendance_activity_id] = approval_activity.id
    attributes
  }
  let(:non_approval_attendance_params) {
    attributes = approval_attendance_params
    attributes[:easy_attendance_activity_id] = non_approval_activity.id
    attributes
  }

  let(:non_approval_attendance) { FactoryGirl.create(:full_day_easy_attendance, :easy_attendance_activity => non_approval_activity, :user => User.current) }
  let(:approval_attendance) { FactoryGirl.create(:full_day_easy_attendance, :easy_attendance_activity => approval_activity, :user => User.current) }

  before(:each) { ActionMailer::Base.deliveries = [] }

  it 'create non approval' do
    post :create, :params => {:easy_attendance => non_approval_attendance_params}
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it 'create approval' do
    post :create, :params => {:easy_attendance => approval_attendance_params}
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it 'update non approval' do
    put :update, :params => {:id => non_approval_attendance, :easy_attendance => {:description => 'updated'}}
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it 'update approval' do
    put :update, :params => {:id => approval_attendance, :easy_attendance => {:description => 'updated'}}
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it 'destroy non approval' do
    post :destroy, :params => {:id => non_approval_attendance}
    expect(ActionMailer::Base.deliveries.size).to eq(0)
  end

  it 'destroy approval' do
    post :destroy, :params => {:id => approval_attendance}
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end
end


