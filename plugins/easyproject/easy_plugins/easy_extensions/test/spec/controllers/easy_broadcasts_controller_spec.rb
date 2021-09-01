require 'easy_extensions/spec_helper'

describe EasyBroadcastsController, logged: :admin do
  let(:easy_broadcast) { FactoryGirl.create(:easy_broadcast) }
  let(:easy_broadcasts) { FactoryGirl.create_list(:easy_broadcast, 5) }
  let(:easy_user_type) { FactoryGirl.create(:test_easy_user_type, internal: false) }
  let(:easy_broadcast_now) { FactoryGirl.create(:easy_broadcast, start_at: Time.now, end_at: Time.now + 1.hour, message: 'bla bla', easy_user_type_ids: [easy_user_type.id]) }

  before(:each) do
    role = Role.non_member
    # role.add_permission! :manage_easy_broadcasts
  end

  render_views

  it 'index' do
    easy_broadcasts

    get :index
    expect(response).to be_successful
    expect(response).to render_template('easy_broadcasts/index')
  end

  # it 'show' do
  #   get :show, :params => {id: easy_broadcast}
  #   expect(response).to be_successful
  #   expect(response).to render_template('easy_broadcasts/show')
  # end

  it 'new' do
    get :new
    expect(response).to be_successful
    expect(response).to render_template('easy_broadcasts/new')
  end

  it 'create with invalid' do
    post :create, params: { easy_broadcast: {} }
    expect(response).to be_successful
    expect(assigns[:easy_broadcast]).to be_a_new(EasyBroadcast)
    expect(response).to render_template('easy_broadcasts/new')
  end

  it 'create with valid' do
    post :create, params: { easy_broadcast: { message: 'Tralala 12123', easy_user_type_ids: [User.current.easy_user_type_id] }, start_at_date: '2012-12-12', start_at_time: '08:00', end_at_date: '2012-12-12', end_at_time: '20:00' }
    expect(assigns[:easy_broadcast]).not_to be_a_new(EasyBroadcast)
    expect(response).to redirect_to(easy_broadcasts_path)
  end

  it 'edit' do
    get :edit, params: { id: easy_broadcast }
    expect(response).to be_successful
    expect(response).to render_template('easy_broadcasts/edit')
  end

  it 'update with invalid' do
    put :update, params: { id: easy_broadcast, easy_broadcast: { message: '' } }
    expect(response).to be_successful
    expect(assigns[:easy_broadcast].valid?).to be false
    expect(response).to render_template('easy_broadcasts/edit')
  end

  it 'update with valid' do
    put :update, params: { id: easy_broadcast, easy_broadcast: { message: 'Tralalala tralala', easy_user_type_ids: [User.current.easy_user_type_id] } }
    expect(assigns[:easy_broadcast].valid?).to be true
    expect(response).to redirect_to(easy_broadcasts_path)
  end

  it 'destroy' do
    easy_broadcast
    easy_broadcasts

    expect(EasyBroadcast.count).to eq(6)
    expect { delete :destroy, params: { id: easy_broadcast } }.to change(EasyBroadcast, :count).by(-1)
    expect(response).to redirect_to(easy_broadcasts_path)
    expect(response).to redirect_to(easy_broadcasts_path)
  end

  it 'validate time range' do
    # 12:00*-------------*14:00 #
    post :create, params: { easy_broadcast: { message: 'first valid', start_at: '2018-10-10 12:00', end_at: '2018-10-10 14:00', easy_user_type_ids: [User.current.easy_user_type_id] } }
    expect(assigns[:easy_broadcast].valid?).to be true
    expect(assigns[:easy_broadcast]).not_to be_a_new(EasyBroadcast)

    #                          12:00*-----------------*14:00
    #invalid     11:00 *--------------------*13:00
    post :create, params: { easy_broadcast: { message: 'start at is in range', start_at: '2018-10-10 11:00', end_at: '2018-10-10 13:00', easy_user_type_ids: [User.current.easy_user_type_id] } }
    expect(assigns[:easy_broadcast].valid?).to be false
    expect(assigns[:easy_broadcast]).to be_a_new(EasyBroadcast)

    #       12:00*-----------------*14:00
    #invalid           13:00 *--------------------*15:00
    post :create, params: { easy_broadcast: { message: 'end at is in range', start_at: '2018-10-10 13:00', end_at: '2018-10-10 15:00', easy_user_type_ids: [User.current.easy_user_type_id] } }
    expect(assigns[:easy_broadcast].valid?).to be false
    expect(assigns[:easy_broadcast]).to be_a_new(EasyBroadcast)

    #     12:00*--------------------------------------------*14:00
    #invalid         12:30 *--------------------*13:30
    post :create, params: { easy_broadcast: { message: 'start_at and and_at is in range', start_at: '2018-10-10 12:30', end_at: '2018-10-10 13:30', easy_user_type_ids: [User.current.easy_user_type_id] } }
    expect(assigns[:easy_broadcast].valid?).to be false
    expect(assigns[:easy_broadcast]).to be_a_new(EasyBroadcast)

    #                      12:00*----------------*14:00
    #invalid  11:00 *------------------------------------------*15:00
    post :create, params: { easy_broadcast: { message: 'start_at and and_at is in range', start_at: '2018-10-10 11:00', end_at: '2018-10-10 15:00', easy_user_type_ids: [User.current.easy_user_type_id] } }
    expect(assigns[:easy_broadcast].valid?).to be false
    expect(assigns[:easy_broadcast]).to be_a_new(EasyBroadcast)

    #                            12:00*----------------*14:00
    #valid  10:00 *-------------*11:59
    post :create, params: { easy_broadcast: { message: 'valid before', start_at: '2018-10-10 10:00', end_at: '2018-10-10 11:59', easy_user_type_ids: [User.current.easy_user_type_id] } }
    expect(assigns[:easy_broadcast].valid?).to be true
    expect(assigns[:easy_broadcast]).not_to be_a_new(EasyBroadcast)

    # 12:00*----------------*14:00
    #valid                   15:01 *-------------*16:00
    post :create, params: { easy_broadcast: { message: 'valid after', start_at: '2018-10-10 15:01', end_at: '2018-10-10 16:00', easy_user_type_ids: [User.current.easy_user_type_id] } }
    expect(assigns[:easy_broadcast].valid?).to be true
    expect(assigns[:easy_broadcast]).not_to be_a_new(EasyBroadcast)
  end

  context 'broadcast per user type', logged: true do

    it 'internals users' do
      easy_broadcast_now
      expect(User.current.easy_user_type.name).to eq 'internal'
      expect(EasyBroadcast.active_for_current_user.count).to eq 0
    end

    it 'non internal users' do
      easy_broadcast_now
      expect {
        User.current.easy_user_type = easy_user_type
        User.current.save
        User.current.reload
      }.to change(User.current, :easy_user_type_id)
      expect(User.current.easy_user_type.name).to eq easy_user_type.name

      expect(EasyBroadcast.active_for_current_user.count).to eq 1
    end

    it 'admins', logged: :admin do
      easy_broadcast_now
      expect(EasyBroadcast.active_for_current_user.count).to eq 1
    end

  end

end
