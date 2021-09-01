RSpec.describe AccountController, type: :controller do

  controller(controller_class) do
    attr_reader :redirected_to

    # Avoid "double render or redirect"
    def redirect_to(url, *)
      @redirected_to = url
    end
  end

  let(:user) { FactoryBot.create(:user) }

  it 'remember device' do
    scheme = EasyTwofa::Auth.for_user(user, 'totp')
    scheme.setup_user_scheme!
    scheme.activate!

    controller.successful_authentication(user)
    expect(controller.redirected_to).to eq(easy_twofa_verification_account_path)

    EasyTwofaRemember.remember_device(scheme, request)

    controller.successful_authentication(user)
    expect(controller.redirected_to).to eq(my_page_path)
  end

end
