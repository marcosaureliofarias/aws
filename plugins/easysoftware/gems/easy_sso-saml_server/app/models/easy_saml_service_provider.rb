class EasySamlServiceProvider < ActiveRecord::Base

  store :settings, accessors: %i[fingerprint metadata_url acs_url], coder: JSON

  validates :identifier, presence: true

  attr_accessor :saml_server_settings

end
