Rails.application.config.middleware.use OmniAuth::Builder do
  provider :saml, setup: ::EasySso::SamlClient::Setup
end
