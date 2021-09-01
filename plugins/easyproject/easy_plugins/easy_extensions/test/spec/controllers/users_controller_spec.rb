require 'easy_extensions/spec_helper'

describe UsersController, :logged => :admin do

  let(:user) { FactoryGirl.create(:user) }

  it 'update preferences' do
    put :update, :params => { :id => user.id, :pref => { :hours_format => 'long', :no_notification_ever => '1' } }
    user.reload
    pref = user.pref
    expect(pref.no_notification_ever).to eq(true)
    expect(pref.hours_format).to eq('long')
    put :update, :params => { :id => user.id, :pref => { :hours_format => 'short', :no_notification_ever => '0' } }
    user.reload
    pref = user.pref
    expect(pref.no_notification_ever).to eq(false)
    expect(pref.hours_format).to eq('short')
  end

  it 'lock' do
    put :update, :params => { :id => user.id, :user => { :status => Principal::STATUS_LOCKED.to_s } }
    expect(user.reload.locked?).to eq(true)
  end

  context '#edit' do
    render_views
    let!(:cf_file) { FactoryBot.create(:user_custom_field, field_format: 'attachment') }

    it 'cf file' do
      get :edit, params: { id: user.id }
      expect(response).to be_successful
    end
  end

  context 'lesser admin permissions' do
    let(:admin_user) { FactoryBot.create(:admin_user) }
    let(:lesser_admin) { FactoryBot.create(:user, easy_lesser_admin: true, easy_lesser_admin_permissions: ['users']) }

    before(:each) { logged_user(lesser_admin) }

    context 'update password' do
      let(:pwd) { 'AaAaAaAaAaAa' }

      it 'regular' do
        user
        expect {
          put :update, params: { id: user.id, user: { password: pwd, password_confirmation: pwd }, format: 'json' }
          expect(response).to be_successful
          user.reload
        }.to change(user, :hashed_password)
      end

      it 'me' do
        expect {
          put :update, params: { id: User.current.id, user: { password: pwd, password_confirmation: pwd }, format: 'json' }
          expect(response).to be_successful
          User.current.reload
        }.to change(User.current, :hashed_password)
      end

      it 'admin' do
        admin_user
        expect {
          put :update, params: { id: admin_user.id, user: { password: pwd, password_confirmation: pwd }, format: 'json' }
          expect(response).to be_successful
          admin_user.reload
        }.not_to change(admin_user, :hashed_password)
      end
    end

    context 'update mail' do
      let(:mail) { 'jarda@fasfsa.com' }

      it 'regular' do
        user
        expect {
          put :update, params: { id: user.id, user: { mail: mail }, format: 'json' }
          expect(response).to be_successful
          user.reload
        }.to change(user, :mail)
      end

      it 'admin' do
        admin_user
        expect {
          put :update, params: { id: admin_user.id, user: { mail: mail }, format: 'json' }
          expect(response).to be_successful
          admin_user.reload
        }.not_to change(admin_user, :mail)
      end
    end

    context 'get api key' do
      render_views
      around(:each) { |ex| with_settings(rest_api_enabled: 1) { ex.run } }

      it 'regular' do
        get :edit, params: { id: user.id }
        expect(response.body).to include(user.api_key)
      end

      it 'admin' do
        get :edit, params: { id: admin_user.id }
        expect(response.body).not_to include(admin_user.api_key)
      end
    end
  end

  it 'update anonymous' do
    expect {
      put :update, params: { id: User.anonymous.id, user: { lastname: 'anon' }, format: 'json' }
    }.not_to change(User.anonymous, :lastname)
    expect(User.anonymous.reload.lastname).not_to eq('anon')
    expect(response).to be_successful
  end

  context 'bulk' do
    let(:users) { FactoryBot.create_list(:user, 2) }

    it 'edit' do
      put :bulk_edit, params: { ids: users.map(&:id), user: { language: 'cs' } }
      expect(response).to be_successful
    end

    it 'update' do
      put :bulk_update, params: { ids: users.map(&:id), user: { language: 'cs' } }
      expect(users.each(&:reload).map(&:language)).to eq(['cs', 'cs'])
    end
  end

  describe 'anonymize user' do
    let(:user_cf_anonymized) { FactoryGirl.create(:user_custom_field, field_format: 'string', clear_when_anonymize: true) }
    let(:user_cf_simple) { FactoryGirl.create(:user_custom_field, field_format: 'string') }
    let(:user1) { FactoryGirl.create(:user,
                                     custom_field_values: {
                                         user_cf_anonymized.id.to_s => 'anonymized',
                                         user_cf_simple.id.to_s     => 'simple'
                                     })
    }

    it 'anonymize' do
      user1
      post :anonymize, params: { id: user1.id }
      user1.reload
      expect(user1.custom_field_value(user_cf_anonymized.id)).to be_nil
      expect(user1.custom_field_value(user_cf_simple.id)).to eq 'simple'

      expect(response).to redirect_to(user_path(user1))
    end

    it 'anonymize anonymous' do
      firstname = User.anonymous.firstname
      lastname  = User.anonymous.lastname
      post :anonymize, params: { id: User.anonymous.id }
      anon = User.anonymous.reload
      expect(anon.firstname).to eq(firstname)
      expect(anon.lastname).to eq(lastname)
      expect(response).to redirect_to(user_path(User.anonymous))
    end

    it 'bulk anonymize' do
      user1
      post :bulk_anonymize, params: { ids: [user1.id] }
      user1.reload
      expect(user1.custom_field_value(user_cf_anonymized.id)).to be_nil
      expect(user1.custom_field_value(user_cf_simple.id)).to eq 'simple'

      expect(response).to redirect_to(users_path)
    end
  end

end
