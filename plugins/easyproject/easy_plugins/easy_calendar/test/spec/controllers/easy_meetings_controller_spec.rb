# encoding: utf-8
require 'easy_extensions/spec_helper'

describe EasyMeetingsController do

  around(:each) do |example|
    with_settings(notified_events: ['meeting']) do
      example.run
    end
  end

  render_views

  context 'with anonymous user' do
    describe 'GET new' do

      it "should not respond with ok" do
        get :new
        expect( response ).not_to be_successful
      end

    end

    describe "PUT update" do
      let!(:meeting) { FactoryGirl.create(:easy_meeting) }

      it "should not change anything" do
        meeting.reload
        expect {
          put :update, :params => {:id => meeting, :easy_meeting => { :name => 'New name', :start_time => Time.now }}
          meeting.reload
        }.to_not change { meeting.attributes }
      end

    end
  end

  context 'with admin user', logged: :admin do
    let(:room) { FactoryBot.create(:easy_room, capacity: 3) }

    describe 'GET show' do
      let(:user) { FactoryBot.create(:user) }
      let(:easy_meeting) { FactoryBot.create(:easy_meeting, user_ids: [user.id]) }

      it 'xml' do
        get :show, params: {id: easy_meeting.id, format: 'xml'}
        expect(response).to be_successful
        expect(response.body).to include("[#{user.id}]")
        expect(response.body).to include("<user_ids type=\"array\">")
      end

      it 'json' do
        get :show, params: {id: easy_meeting.id, format: 'json'}
        expect(response).to be_successful
        expect(response.body).to include("[#{user.id}]")
        expect(response.body).to include("\"user_ids\":[#{user.id}]")
      end
    end

    describe 'GET new' do

      it "should return a new form" do
        get :new
        expect( response.body ).to have_css('form#new_easy_meeting')
      end

      it "should not render layout for xhr requests" do
        get :new, :xhr => true
        expect( response.body ).to have_css('form#new_easy_meeting')
        expect( response.body ).not_to have_css('div#content')
      end

      it "should fill attributes from params" do
        start_time = Time.now
        end_time = start_time + 2.hours
        get :new, :params => {:easy_meeting => { :name => 'Param name', :start_time => start_time, :end_time => end_time }}

        expect( response.body ).to have_selector("input[name='easy_meeting[name]'][value='Param name']")
        expect( response.body ).to have_selector("input[name='easy_meeting[start_time][date]'][value='#{start_time.to_date.to_param}']")
        expect( response.body ).to have_selector("input[name='easy_meeting[start_time][time]'][value='#{start_time.strftime('%H:%M')}']")
        expect( response.body ).to have_selector("input[name='easy_meeting[end_time][date]'][value='#{end_time.to_date.to_param}']")
        expect( response.body ).to have_selector("input[name='easy_meeting[end_time][time]'][value='#{end_time.strftime('%H:%M')}']")
      end

    end

    describe 'POST create with json format' do
      it "creates a meeting if attributes are valid" do
        meeting_attrs = FactoryGirl.attributes_for(:easy_meeting)
        meeting_attrs[:user_ids] = [User.current.id]
        expect {post :create, params: {:format => 'json', :easy_meeting => meeting_attrs}}.to change(EasyMeeting, :count).by(1)
        meeting = EasyMeeting.last
        expect( meeting.author_id ).to eq( User.current.id )
        expect( meeting.name ).to eq( meeting_attrs[:name] )
        expect( meeting.description ).to eq( meeting_attrs[:description] )
        expect( meeting.start_time.utc.to_param ).to eq( meeting_attrs[:start_time].utc.to_param )
        expect( meeting.end_time.utc.to_param ).to eq( meeting_attrs[:end_time].utc.to_param )
      end

      it "renders validation errors if attributes are not valid" do
        meeting_attrs = FactoryGirl.attributes_for(:easy_meeting)
        meeting_attrs[:name] = ''
        expect {post :create, :params => {:format => 'json', :easy_meeting => meeting_attrs}}.not_to change(EasyMeeting, :count)

        expect( response ).to have_http_status( 422 )
        expect( json[:errors][0] ).to include("Name cannot be blank")
      end

      it "does not allow to invite more users than the capacity of the meeting room" do
        meeting_attrs = FactoryGirl.attributes_for(:easy_meeting)
        meeting_attrs[:easy_room_id] = room.id
        meeting_attrs[:mails] = 'user1@example.com, user2@example.com, user3@example.com, user4@example.com'
        expect {post :create, :params => {:format => 'json', :easy_meeting => meeting_attrs}}.not_to change(EasyMeeting, :count)
      end

      it "does not allow to create multiple meetings in the same room at the same time" do
        meeting_attrs = FactoryGirl.attributes_for(:easy_meeting)
        meeting_attrs[:user_ids] = [User.current.id]
        meeting_attrs[:easy_room_id] = room.id
        expect {post :create, params: {:format => 'json', :easy_meeting => meeting_attrs}}.to change(EasyMeeting, :count).by(1)
        expect( response ).to have_http_status(:created)
        expect {post :create, params: {:format => 'json', :easy_meeting => meeting_attrs}}.not_to change(EasyMeeting, :count)
        expect( response ).to have_http_status( 422 )

        expect( json[:errors][0] ).to include("There is another meeting in the same room")
      end
    end

    describe 'PUT update with json format' do
      # only authors can update their meetings
      let(:meeting) { FactoryGirl.create(:easy_meeting, author: User.current) }

      it "updates attributes" do
        put :update, :params => {id: meeting, format: 'json', easy_meeting: {name: 'Updated name'}}
        meeting.reload
        expect( meeting.name ).to eq( 'Updated name' )
      end

      it "renders validation errors" do
        put :update, :params => {:id => meeting.id, :format => 'json', :easy_meeting => {:name => ''}}
        expect( response ).to have_http_status 422
        err = I18n.t(:field_name)
        err << ' ' << I18n.t(:'activerecord.errors.messages.blank')
        expect( json[:errors][0] ).to include(err)
      end

      context 'reset invitations' do
        let(:user) { FactoryBot.create(:user) }
        let(:meeting) { FactoryBot.create(:easy_meeting, author: User.current) }
        before do
          meeting.easy_invitations.create(user_id: user.id, accepted: true)
        end

        it 'should send new invitations' do
          expect(meeting.easy_invitations.to_a).to match_array([
            have_attributes(user_id: User.current.id, accepted: true),
            have_attributes(user_id: user.id, accepted: true)
          ])
          expect(EasyCalendar::EasyMeetingNotifier).to receive(:call).with(meeting)
          put :update, params: { id: meeting.id, easy_meeting: { start_time: meeting.start_time + 10.minutes, name: 'Updated name', reset_invitations: true }, format: :json }
          expect(meeting.reload.easy_invitations.to_a).to match_array([
            have_attributes(user_id: User.current.id, accepted: true),
            have_attributes(user_id: user.id, accepted: nil)
          ])
        end

        it 'should send invitations without reset' do
          expect(meeting.easy_invitations.to_a).to match_array([
            have_attributes(user_id: User.current.id, accepted: true),
            have_attributes(user_id: user.id, accepted: true)
          ])
          expect(EasyCalendar::EasyMeetingNotifier).to receive(:call).with(meeting)
          put :update, params: { id: meeting.id, easy_meeting: { start_time: meeting.start_time + 10.minutes, name: 'Updated name', reset_invitations: false }, format: :json }
          expect(meeting.reload.easy_invitations.to_a).to match_array([
            have_attributes(user_id: User.current.id, accepted: true),
            have_attributes(user_id: user.id, accepted: true)
          ])
        end
      end
    end

    describe 'DELETE destroy with json format' do
      shared_examples 'destroy meeting' do |name|
        let!(:recurring_meeting) { FactoryBot.create(:easy_meeting, :reccuring, start_time: Time.now) }
        let!(:repeated1) { FactoryBot.create(:easy_meeting, easy_repeat_parent_id: recurring_meeting.id, start_time: Time.now + 1.day) }
        let!(:repeated2) { FactoryBot.create(:easy_meeting, easy_repeat_parent_id: recurring_meeting.id, start_time: Time.now + 2.day) }
        let(:params) { {} }

        subject { -> { delete :destroy, params: {id: meeting_to_destroy.id, format: 'json'}.merge(params) }  }

        it "#{name}" do
          expect { subject.call }.to change { EasyMeeting.count }.by(-expected_count)
          expect(EasyMeeting.all).to match_array(Array(expected_array))
        end
      end

      before do
        allow_any_instance_of(EasyMeeting).to receive(:create_repeated).and_return(true)
      end

      it_behaves_like('destroy meeting', 'reccuring (parent)') do
        let(:meeting_to_destroy) { recurring_meeting }
        let(:expected_array) { [repeated1, repeated2] }
        let(:expected_count) { 1 }
      end

      it_behaves_like('destroy meeting', 'event') do
        let(:meeting_to_destroy) { repeated1 }
        let(:expected_array) { [recurring_meeting, repeated2] }
        let(:expected_count) { 1 }
      end

      it_behaves_like('destroy meeting', 'all repeating events') do
        let(:meeting_to_destroy) { repeated1 }
        let(:params) { {repeating: '1'}}
        let(:expected_array) { [] }
        let(:expected_count) { 3 }
      end

      it_behaves_like('destroy meeting', 'current_and_following') do
        let(:meeting_to_destroy) { repeated1 }
        let(:params) { {current_and_following: '1'}}
        let(:expected_array) { [recurring_meeting] }
        let(:expected_count) { 2 }
      end
    end

    describe 'User invitations' do
      let(:english_user) { FactoryGirl.create(:user, language: 'en') }
      let(:spanish_user) { FactoryGirl.create(:user, language: 'es') }
      let(:meeting) { FactoryGirl.create(:easy_meeting, mails: 'external1@example.com, external2@example.com', author: User.current) }
      let(:project) { FactoryGirl.create(:project) }

      before do
        ActionMailer::Base.deliveries = []
      end

      it "invites users and external users on creation" do
        meeting_attrs = FactoryGirl.attributes_for(:easy_meeting, {
          user_ids: [spanish_user.id, english_user.id],
          mails: 'external1@example.com, external2@example.com'
        })

        post :create, :params => {:format => 'json', :easy_meeting => meeting_attrs}
        [
          spanish_user.mail,
          english_user.mail,
          'external1@example.com',
          'external2@example.com'
        ].each do |mail|
          msg = ActionMailer::Base.deliveries.detect {|msg| msg.bcc == [mail]}
          expect( msg ).not_to be_nil
          expect( msg.attachments.detect{|a| /application\/ical/.match?(a.content_type) } ).not_to be_nil
          expect( msg.html_part.body.to_s ).to include( meeting_attrs[:description] )
        end
      end

      it "invites added external users on update" do
        put :update, :params => {id: meeting, format: 'json', easy_meeting: {mails: "#{meeting.mails}, external3@example.com"}}
        msg = ActionMailer::Base.deliveries.detect {|msg| msg.bcc == ['external3@example.com']}
        expect( msg ).not_to be_nil
      end

      it "invites users in their language" do
        meeting_attrs = FactoryGirl.attributes_for(:easy_meeting, user_ids: [spanish_user.id])
        post :create, :params => {format: 'json', easy_meeting: meeting_attrs}
        expect( ActionMailer::Base.deliveries.last.subject ).to include('Invitación a una reunión')
      end

      it "has project name in notification email subject" do
        meeting_attrs = FactoryGirl.attributes_for(:easy_meeting, user_ids: [english_user.id], project_id: project.id)
        post :create, :params => {format: 'json', easy_meeting: meeting_attrs}
        msg = ActionMailer::Base.deliveries.last
        expect( msg.subject ).to include(project.name)
      end

      it "has description in notification email body" do
        description = 'This is a meeting description.'
        meeting_attrs = FactoryGirl.attributes_for(:easy_meeting, user_ids: [english_user.id], mails: 'test@example.com', description: description)
        post :create, :params => {format: 'json', easy_meeting: meeting_attrs}
        expect( ActionMailer::Base.deliveries.size ).to eq( 2 )
        ActionMailer::Base.deliveries.each do |msg|
          expect( msg.html_part.body.to_s ).to include(description)
        end
      end
    end

    describe 'Accept or decline' do

      context 'reflect_on_big_recurring_childs' do
        let(:user) { FactoryGirl.create(:user) }
        let!(:parent_meeting) { FactoryBot.create(:easy_meeting, author: user, big_recurring: true) }
        let!(:child_meeting) { FactoryBot.create(:easy_meeting, author: user, easy_repeat_parent: parent_meeting) }

        before do
          parent_meeting.easy_invitations.create(user_id: User.current.id)
          child_meeting.easy_invitations.create(user_id: User.current.id)
        end

        context 'Accept' do
          it 'should accept all future meetings' do
            expect(parent_meeting.easy_invitations.to_a).to match_array([
              have_attributes(user_id: User.current.id, accepted: nil),
              have_attributes(user_id: user.id, accepted: true)
            ])

            post :accept, params: { id: parent_meeting.id, reflect_on_big_recurring_childs: true }

            expect(parent_meeting.reload.easy_invitations.to_a).to match_array([
              have_attributes(user_id: User.current.id, accepted: true),
              have_attributes(user_id: user.id, accepted: true)
            ])
            expect(child_meeting.reload.easy_invitations.to_a).to match_array([
              have_attributes(user_id: User.current.id, accepted: true),
              have_attributes(user_id: user.id, accepted: true)
            ])
          end

          it 'should accept only one current' do
            expect(parent_meeting.easy_invitations.to_a).to match_array([
              have_attributes(user_id: User.current.id, accepted: nil),
              have_attributes(user_id: user.id, accepted: true)
            ])

            post :accept, params: { id: parent_meeting.id, reflect_on_big_recurring_childs: false }

            expect(parent_meeting.reload.easy_invitations.to_a).to match_array([
              have_attributes(user_id: User.current.id, accepted: true),
              have_attributes(user_id: user.id, accepted: true)
            ])
            expect(child_meeting.reload.easy_invitations.to_a).to match_array([
              have_attributes(user_id: User.current.id, accepted: nil),
              have_attributes(user_id: user.id, accepted: true)
            ])
          end
        end

        context 'Decline' do
          it 'should decline all future meetings' do
            expect(parent_meeting.easy_invitations.to_a).to match_array([
              have_attributes(user_id: User.current.id, accepted: nil),
              have_attributes(user_id: user.id, accepted: true)
            ])

            post :decline, params: { id: parent_meeting.id, reflect_on_big_recurring_childs: true }

            expect(parent_meeting.reload.easy_invitations.to_a).to match_array([
              have_attributes(user_id: User.current.id, accepted: false),
              have_attributes(user_id: user.id, accepted: true)
            ])
            expect(child_meeting.reload.easy_invitations.to_a).to match_array([
              have_attributes(user_id: User.current.id, accepted: false),
              have_attributes(user_id: user.id, accepted: true)
            ])
          end

          it 'should decline only one current' do
            expect(parent_meeting.easy_invitations.to_a).to match_array([
              have_attributes(user_id: User.current.id, accepted: nil),
              have_attributes(user_id: user.id, accepted: true)
            ])

            post :decline, params: { id: parent_meeting.id, reflect_on_big_recurring_childs: false }

            expect(parent_meeting.reload.easy_invitations.to_a).to match_array([
              have_attributes(user_id: User.current.id, accepted: false),
              have_attributes(user_id: user.id, accepted: true)
            ])
            expect(child_meeting.reload.easy_invitations.to_a).to match_array([
              have_attributes(user_id: User.current.id, accepted: nil),
              have_attributes(user_id: user.id, accepted: true)
            ])
          end
        end

        context 'Remove meeting send notification to accepted users' do
          before do
            ActionMailer::Base.deliveries = []
          end

          let(:easy_parent_meeting_hash) { parent_meeting.attributes.to_json(only: %w{name all_day start_time end_time}) }
          let(:easy_child_meeting_hash) { child_meeting.attributes.to_json(only: %w{name all_day start_time end_time}) }

          it 'default' do
            expect { delete :destroy, params: {id: parent_meeting.id, format: 'json'} }
              .to have_enqueued_job(ActionMailer::DeliveryJob)
                .with(
                  'EasyCalendarMailer',
                  'easy_meeting_removal',
                  'deliver_now',
                  user,
                  easy_parent_meeting_hash
                )
          end

          it 'all accepted users' do
            post :accept, params: { id: parent_meeting.id, reflect_on_big_recurring_childs: true }

            expect { delete :destroy, params: {id: parent_meeting.id, format: 'json'} }
              .to have_enqueued_job(ActionMailer::DeliveryJob).exactly(2).times
              .and have_enqueued_job(ActionMailer::DeliveryJob)
                .with(
                  'EasyCalendarMailer',
                  'easy_meeting_removal',
                  'deliver_now',
                  user,
                  easy_parent_meeting_hash
                )
              .and have_enqueued_job(ActionMailer::DeliveryJob)
                .with(
                  'EasyCalendarMailer',
                  'easy_meeting_removal',
                  'deliver_now',
                  User.current,
                  easy_parent_meeting_hash
              )
          end
        end
      end

    end
  end

end
