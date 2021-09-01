require 'rys'

require 'easy_sso'
require 'easy_sso/saml_client/version'
require 'easy_sso/saml_client/engine'

require 'onelogin/ruby-saml'
require 'omniauth-saml'

module EasySso
  module SamlClient

    autoload :Setup, 'easy_sso/saml_client/setup'

    def self.saml_settings
      settings = OneLogin::RubySaml::Settings.new

      hash_settings.each do |k, v|
        next if v.blank?

        settings.send("#{k}=", v)
      end

      settings
    end

    def self.hash_settings
      h = {
          assertion_consumer_service_url:     EasySso::SamlClient::Settings.assertion_consumer_service_url,
          assertion_consumer_service_binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST",
          issuer:                             EasySso::SamlClient::Settings.issuer,
          idp_sso_target_url:                 EasySso::SamlClient::Settings.idp_sso_target_url,
          idp_cert_fingerprint:               EasySso::SamlClient::Settings.idp_cert_fingerprint,
          idp_cert:                           EasySso::SamlClient::Settings.idp_cert,
          name_identifier_format:             EasySso::SamlClient::Settings.name_identifier_format,
          name_identifier_value:              EasySso::SamlClient::Settings.name_identifier_value
      }

      if EasySso::SamlClient::Settings.use_sp_certificate?
        h[:certificate] = EasySso::SamlClient::Settings.sp_certificate
        h[:private_key] = EasySso::SamlClient::Settings.sp_certificate_private_key
      end

      h
    end

    module User
      class << self

        def login(response)
          response.attributes.single(EasySso::SamlClient::Settings.attribute_mapping_login)
        end

        def mail(response)
          response.attributes.single(EasySso::SamlClient::Settings.attribute_mapping_mail)
        end

        def first_name(response)
          response.attributes.single(EasySso::SamlClient::Settings.attribute_mapping_firstname)
        end

        def last_name(response)
          response.attributes.single(EasySso::SamlClient::Settings.attribute_mapping_lastname)
        end

      end
    end

    module Settings
      class << self

        def default_url_options
          if Rails.env.production?
            { protocol: Setting.protocol, host: Setting.host_name }
          else
            { protocol: "http", host: "localhost", port: "3000" }
          end
        end

        def host_name
          if Rails.env.production?
            "#{Setting.protocol}://#{Setting.host_name}"
          else
            "http://localhost:3000"
          end
        end

        def setting(name)
          EasySetting.value("easy_sso_saml_client_#{name}").presence
        end

        def assertion_consumer_service_url
          Rails.application.routes.url_helpers.easy_sso_saml_client_callback_url(default_url_options)
        end

        def issuer
          host_name
        end

        def metadata_url
          Rails.application.routes.url_helpers.easy_sso_saml_client_metadata_url(default_url_options)
        end

        def login_url
          host_name + EasyExtensions::IdentityProviders.registered['saml_client'].login_path
        end

        def name
          setting('name') || I18n.t(:title, scope: [:rys_features, :easy_sso_saml_client])
        end

        def idp_sso_target_url
          setting('idp_sso_target_url')
        end

        def single_logout_service_url
          setting('single_logout_service_url') || Rails.application.routes.url_helpers.easy_sso_saml_client_sls_url(default_url_options)
        end

        def idp_cert_fingerprint
          setting('idp_cert_fingerprint')
        end

        def idp_cert
          setting('idp_cert')
        end

        def name_identifier_format
          setting('name_identifier_format') || "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
        end

        def idp_slo_target_url
          setting('idp_slo_target_url')
        end

        def debug?
          setting('debug') == '1'
        end

        def idp_checked?
          setting('idp_checked') == '1'
        end

        def idp_checked!
          idp_checked_setting = EasySetting.find_or_initialize_by(name: "easy_sso_saml_client_idp_checked")
          idp_checked_setting.value = '1'
          idp_checked_setting.save
        end

        def use_sp_certificate?
          setting('use_sp_certificate') == '1'
        end

        def ensure_sp_certificate
          if EasySetting.value("easy_sso_saml_client_sp_certificate").blank? || EasySetting.value("easy_sso_saml_client_sp_certificate_private_key").blank?
            cert    = EasySso::SelfSignedCertificate.generate(org_unit:    EasyExtensions::EasyProjectSettings.app_name,
                                                              email:       EasyExtensions::EasyProjectSettings.app_email,
                                                              common_name: EasyExtensions.domain_name)
            wrapper = EasySettings::ParamsWrapper.from_params({ easy_sso_saml_client_sp_certificate:             cert.certificate,
                                                                easy_sso_saml_client_sp_certificate_private_key: cert.private_key }.with_indifferent_access)
            wrapper.save
          end
        end

        def sp_certificate
          ensure_sp_certificate
          setting('sp_certificate')
        end

        def sp_certificate_private_key
          ensure_sp_certificate
          setting('sp_certificate_private_key')
        end

        def validation?
          setting('validation').nil? || setting('validation') == '1'
        end

        def onthefly_creation?
          setting('onthefly_creation') == '1'
        end

        def login_button?
          setting('login_button') == '1'
        end

        def name_identifier_value
          setting('name_identifier_value') || "mail"
        end

        def attribute_mapping_login
          setting('attribute_mapping_login') || "username"
        end

        def attribute_mapping_mail
          setting('attribute_mapping_mail') || "mail"
        end

        def attribute_mapping_firstname
          setting('attribute_mapping_firstname') || "first_name"
        end

        def attribute_mapping_lastname
          setting('attribute_mapping_lastname') || "last_name"
        end

      end
    end
  end
end
