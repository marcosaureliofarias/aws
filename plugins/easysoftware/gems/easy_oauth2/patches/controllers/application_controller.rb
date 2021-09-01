Rys::Patcher.add('ApplicationController') do

  apply_if_plugins :easy_extensions

  included do
  end

  instance_methods(feature: 'easy_oauth2') do
    def find_current_user_alternative
      user = super

      return user if user

      token_value  = Array(ActionController::HttpAuthentication::Token.token_and_options(request)).first

      return nil unless token_value

      access_grant = EasyOauth2AccessGrant.valid_for(token_value).first

      if access_grant && (user = access_grant.user) && user.active?
        user
      else
        nil
      end
    end
  end

end
