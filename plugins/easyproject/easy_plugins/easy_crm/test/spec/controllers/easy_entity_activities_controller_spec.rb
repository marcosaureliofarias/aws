require_relative '../spec_helper'

describe EasyEntityActivitiesController, logged: :admin do

  let(:easy_crm_case){ FactoryGirl.create(:easy_crm_case) }
  let(:easy_entity_activity_category) { FactoryGirl.create(:easy_entity_activity_category) }
  let(:easy_entity_activity) { FactoryGirl.create(:easy_entity_activity, entity: easy_crm_case) }
  let(:user){ FactoryGirl.create(:user) }

  it 'create without easy_entity_activity_attendees' do
    post :create, params: {easy_entity_activity: {entity_type: 'EasyCrmCase', entity_id: easy_crm_case.id, start_time: {date: '2017-04-18', time: '10:01'}, all_day: '0', category_id: easy_entity_activity_category.id, is_finished: '1'}, format: 'js'}
    expect(assigns[:easy_entity_activity]).not_to be_a_new(EasyEntityActivity)
    expect(response).to be_successful
    expect(EasyEntityActivity.all.count).to eq(1)
  end

  it 'create with easy_entity_activity_attendees' do
    post :create, params: {easy_entity_activity: {entity_type: 'EasyCrmCase', entity_id: easy_crm_case.id, start_time: {date: '2017-04-18', time: '10:01'}, all_day: '0', category_id: easy_entity_activity_category.id, is_finished: '1'}, easy_entity_activity_attendees: {Principal: [user.id], EasyContact: []}, format: 'js'}
    expect(assigns[:easy_entity_activity]).not_to be_a_new(EasyEntityActivity)
    expect(response).to be_successful
    expect(EasyEntityActivity.all.count).to eq(1)
  end

  it 'update activity start time' do
    put :update, params: {id: easy_entity_activity.id, easy_entity_activity: { start_time: {date: '2017-04-18', time: '10:01'}}}
    expect(assigns[:easy_entity_activity].start_time).to be_a(Time)
  end

  it 'update crm journal' do
    expect(easy_entity_activity.is_finished?).to eq(false)
    put :update, params: {id: easy_entity_activity.id, easy_entity_activity: {entity_type: 'EasyCrmCase', entity_id: easy_crm_case.id, start_time: {date: '2017-04-18', time: '10:01'}, all_day: '0', category_id: easy_entity_activity_category.id, is_finished: '1', description: 'done'}, easy_entity_activity_attendees: {Principal: [user.id], EasyContact: []}, format: 'js'}
    expect(assigns[:easy_entity_activity].errors.messages).to be_blank
    expect(assigns[:easy_entity_activity].is_finished?).to eq(true)
    expect(assigns[:easy_entity_activity].entity.journals.last.notes.to_s).to include('done')
  end

  context 'create with end_time' do
    let(:attributes) {
      {
        entity_type: 'EasyCrmCase',
        entity_id: easy_crm_case.id,
        start_time: {date: '2017-04-18', time: '10:01'},
        end_time: {date: '2017-04-18', time: '11:01'},
        category_id: easy_entity_activity_category.id,
      }
    }

    it 'correct end_time :success' do
      expect {
        post :create, params: {easy_entity_activity: attributes, format: 'js'}
      }.to change(EasyEntityActivity, :count).by(1)
      end_time = User.current.user_time_in_zone(assigns(:easy_entity_activity).end_time)
      expect(end_time).to eq User.current.user_time_in_zone('2017-04-18 11:01')
    end

    it 'end_time is nil :success' do
      attributes.delete(:end_time)
      expect {
        post :create, params: {easy_entity_activity: attributes, format: 'js'}
      }.to change(EasyEntityActivity, :count).by(1)
      end_time = User.current.user_time_in_zone(assigns(:easy_entity_activity).end_time)
      expect(end_time).to eq assigns(:easy_entity_activity).start_time + 15.minutes
    end

    it 'end_time is less than start_time :failed' do
      attributes[:end_time] = {date: '2017-04-18', time: '08:00'}
      expect {
        post :create, params: {easy_entity_activity: attributes, format: 'js'}
      }.to change(EasyEntityActivity, :count).by(0)
      expect(response.status).to eq(422)
    end
  end
end