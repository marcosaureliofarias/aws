class EasySsoSamlClientCallbacksController < AccountController

  skip_before_action :verify_authenticity_token, only: [:easy_sso_saml_consume, :easy_sso_saml_sls]

  def easy_sso_saml_consume
    @saml_response = OneLogin::RubySaml::Response.new(params['SAMLResponse'], settings: EasySso::SamlClient.saml_settings)

    if EasySso::SamlClient::Settings.debug? || !EasySso::SamlClient::Settings.idp_checked?
      debug_callback
    elsif (EasySso::SamlClient::Settings.validation? && @saml_response.is_valid?(true)) || !EasySso::SamlClient::Settings.validation?
      login_callback
    else
      flash[:error] = "SAML ERROR: #{@saml_response.errors.join('. ')}"
      redirect_to signin_path
    end
  rescue OneLogin::RubySaml::ValidationError => ex
    flash[:error] = "SAML ERROR: #{ex.message}"
    redirect_to signin_path
  end

  private

  def find_user_from_saml_response
    case EasySso::SamlClient::Settings.name_identifier_value
    when 'mail'
      User.having_mail(@saml_response.name_id).first
    when 'login'
      User.where(User.arel_table[:login].lower.eq(@saml_response.name_id.to_s.downcase)).first
    end
  end

  def login_callback
    user = find_user_from_saml_response

    if user.nil?
      if EasySso::SamlClient::Settings.onthefly_creation?
        user = prepare_saml_user

        register_automatically(user) do
          onthefly_creation_failed(user)
        end
      else
        flash[:error] = "Cannot create new user, because on the fly creation is disabled."
        redirect_to signin_path
      end

      return
    end

    if user.active?
      user.update_last_login_on! if !user.new_record?
      successful_authentication(user)
      update_sudo_timestamp! # activate Sudo Mode
    else
      handle_inactive_user(user)
    end
  end

  def debug_callback
    @test_user = find_user_from_saml_response || prepare_saml_user
    EasySso::SamlClient::Settings.idp_checked! if @test_user && @test_user.valid? && !EasySso::SamlClient::Settings.idp_checked?
    @xml_response = Nokogiri.parse(@saml_response.document.to_s) if @saml_response.document

    render template: 'easy_sso_saml_client_callbacks/debug'
  end

  def prepare_saml_user
    user = User.new
    user.login = EasySso::SamlClient::User.login(@saml_response)
    user.mail = EasySso::SamlClient::User.mail(@saml_response)
    user.firstname = EasySso::SamlClient::User.first_name(@saml_response)
    user.lastname = EasySso::SamlClient::User.last_name(@saml_response)
    user.sso_provider = 'saml'
    user.sso_uuid = @saml_response.name_id
    user.self_registered = true
    user.random_password
    user.register
    user
  end

end
