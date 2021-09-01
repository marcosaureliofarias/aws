require 'easy_extensions/spec_helper'

describe EasyAttendanceActivitiesController do

  before(:each)                { logged_user(user) } # admin

  let!(:user)                  { FactoryGirl.create(:admin_user) }
  let!(:attendance_activity1)  { FactoryGirl.create(:vacation_easy_attendance_activity) }
  let!(:attendance_activity2)  { FactoryGirl.create(:vacation_easy_attendance_activity) }
  let(:activity_params)        { EasyAttendanceActivity.where(:at_work => false).all.each_with_object({}){ |c,h| h[c.id] = 10 } }
  let(:params) {
    {
      :easy_attendance_activity_user_limit => activity_params,
      :user_id => user.id
    }
  }
  let(:updated_value) {
    999
  }

  describe 'POST user vacation limits' do

    it 'creates user activity limits' do
      expect {
        post :set_user_attendace_activity_limits, :params => params
      }.to change(user.easy_attendance_activity_user_limits, :count).by(EasyAttendanceActivity.where(:at_work => false).count)

      expect( response ).to have_http_status(302)
    end

    it 'updates user activity limits' do
      expect {
        post :set_user_attendace_activity_limits, :params => params
      }.to change(user.easy_attendance_activity_user_limits, :count).by(EasyAttendanceActivity.where(:at_work => false).count)

      new_params = params
      new_params[:easy_attendance_activity_user_limit][attendance_activity1.id] = updated_value
      expect {
        post :set_user_attendace_activity_limits, :params => new_params
      }.to change(user.easy_attendance_activity_user_limits, :count).by(0)

      user.reload
      expect( user.easy_attendance_activity_user_limits.where(:easy_attendance_activity_id => attendance_activity1.id).first.days ).to eq( updated_value )
    end

  end

  context 'edit', :logged => :admin do
    render_views

    it 'get' do
      get :edit, :params => {:id => attendance_activity1.id}
      expect( response ).to be_successful
    end
  end

end
