require 'easy_extensions/spec_helper'

describe AccountController do
  context 'registration', :logged => :admin  do
    it '#register' do
      post :register, params: { user: { mail: 'test@test.com', firstname: 'xxx', lastname: 'xxx', login: 'xxx', password: '123456789', password_confirmation: '123456789' } }
      expect(assigns(:user)).to be_persisted
      expect(assigns(:user).self_registered).to eq(true)
    end
  end

  context "proper redirection after lost_password" do
    subject { post :lost_password, params: { mail: 'fake@fake.fake' } }

    it 'redirect to login screen when user not exists' do
      expect(subject).to redirect_to(signin_path)
    end

    it 'flash is unified' do
      expect(subject.request.flash[:notice]).to_not be_nil
      expect(subject.request.flash[:notice]).to eq(I18n.t('notice_account_lost_email_sent_unified'))
    end
  end
end
