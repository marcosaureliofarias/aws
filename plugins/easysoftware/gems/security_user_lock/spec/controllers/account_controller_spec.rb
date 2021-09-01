RSpec.describe AccountController, type: :controller, logged: :admin do

  let(:user) { FactoryBot.create(:user, password: 'Test1234.') }

  def settings(v1, v2, v3)
    { user_login_attempts: v1, user_locking_time: v2, user_locking_period: v3}
  end

  it 'disabled feature' do
    with_easy_settings(settings(0,1,1)) do
      login = user.login
      post :login, params: {username: login, password: 'bad'}
      post :login, params: {username: login, password: 'Test1234.'}
      user.reload
      expect(user.blocked_at).to be nil
    end
  end

  it 'lock user after reaching limit failed attempts' do
    with_easy_settings(settings(1,1,1)) do
      login = user.login
      post :login, params: {username: login, password: 'bad'}
      post :login, params: {username: login, password: 'Test1234.'}
      user.reload
      expect(user.blocked_at).not_to be nil
    end
  end

end
