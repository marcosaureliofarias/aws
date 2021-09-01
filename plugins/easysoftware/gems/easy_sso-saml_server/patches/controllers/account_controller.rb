Rys::Patcher.add('AccountController') do

  apply_if_plugins :easy_extensions

  included do

    include SamlIdp::Controller

    prepend_before_action :validate_saml_request2, only: [:login]
    prepend_before_action :configure_saml

  end

  instance_methods do

    def saml_idp_metadata
      render xml: SamlIdp.metadata.signed
    end

    protected

    def successful_authentication_redirect_url(user)
      if params[:SAMLRequest].present?
        @saml_response = encode_response(user)

        render template: "saml_idp/idp/saml_post", layout: false

        return true
      else
        super
      end
    end

    private

    def validate_saml_request2
      return true if params[:SAMLRequest].blank?

      decode_request(params[:SAMLRequest])

      return true if valid_saml_request?

      render_error(message: l(:error_invalid_saml_request, scope: :easy_sso_saml_server), status: 403)

      false
    end

    def configure_saml
      saml_settings = SamlServerSettings.new
      base_url      = EasySso::SamlServer::Settings.host_name

      SamlIdp.configure do |config|
        config.x509_certificate = EasySso::SamlServer::Settings.x509_certificate
        config.secret_key       = EasySso::SamlServer::Settings.secret_key

        #config.password          = EasySso::SamlServer::Settings.password
        config.algorithm          = EasySso::SamlServer::Settings.algorithm
        config.organization_name  = EasyExtensions::EasyProjectSettings.app_name
        config.organization_url   = base_url
        config.base_saml_location = base_url
        # config.reference_id_generator                                 # Default: -> { UUID.generate }
        config.single_logout_service_post_location     = "#{base_url}/logout"
        config.single_logout_service_redirect_location = "#{base_url}/logout"
        # config.attribute_service_location = "#{base}/saml/attributes"
        config.single_service_post_location = "#{base_url}/login"
        # config.session_expiry = 86400                                 # Default: 0 which means never

        config.name_id.formats =
            {
                email_address: -> (user) { user.mail },
                transient:     -> (user) { user.id },
                persistent:    -> (p) { p.id }
            }

        config.attributes = {
            "Login"         => {
                "name"        => "login",
                "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
                "getter"      => ->(user) {
                  user.login
                },
            },
            "Email address" => {
                "name"        => "email",
                "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
                "getter"      => ->(user) {
                  user.mail
                },
            },
            "Full name"     => {
                "name"        => "name",
                "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
                "getter"      => ->(user) {
                  user.name
                }
            },
            "Given name"    => {
                "name"        => "first_name",
                "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
                "getter"      => ->(user) {
                  user.firstname
                }
            },
            "Family name"   => {
                "name"        => "last_name",
                "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
                "getter"      => ->(user) {
                  user.lastname
                }
            }
        }

        service_providers = {}
        saml_settings.service_providers.each do |service_provider|
          service_providers[service_provider.identifier] = {
              #fingerprint:  "83:E5:45:2B:FA:1F:63:E1:46:54:AE:B9:ED:D7:56:B4:A4:77:7F:72:70:FD:E3:D8:C8:58:D7:D1:13:C2:4D:37",
              metadata_url: service_provider.metadata_url,
              acs_url: service_provider.acs_url,

              # We now validate AssertionConsumerServiceURL will match the MetadataURL set above.
              # *If* it's not going to match your Metadata URL's Host, then set this so we can validate the host using this list
              response_hosts: [service_provider.acs_url]
          }
        end

        config.service_provider.finder = ->(issuer_or_entity_id) do
          service_providers[issuer_or_entity_id]
        end
      end
    end

  end

  class_methods do
  end

end
