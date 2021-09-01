module EasyOauth2
  class Setup

    def self.call(env)
      new(env).setup
    end

    def initialize(env)
      @env     = env
      @request = ::ActionDispatch::Request.new(env)
    end

    def setup
      @env['omniauth.strategy'].options.merge!(options_from_application)
    end

    def options_from_application
      app = EasyOauth2ClientApplication.active.find_by(guid: @request.params[:guid])

      raise ArgumentError, "Cannot find EasyOauth2ClientApplication, guid: #{@request.params[:guid]}" unless app

      h = {}

      if app
        h[:client_id]      = app.app_id
        h[:client_secret]  = app.app_secret
        h[:client_options] = {
            site:          app.app_url,
            authorize_url: app.authorize_url.presence || '/oauth/authorize',
            token_url:     app.token_url.presence || '/oauth/token',
            user_info_url: app.user_info_url.presence || '/oauth/user'
        }
      end

      h
    end

  end
end
