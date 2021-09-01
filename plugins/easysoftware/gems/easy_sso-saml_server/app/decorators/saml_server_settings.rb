class SamlServerSettings
  include ActiveModel::Model

  attr_reader :service_providers

  def initialize
    @service_providers = EasySamlServiceProvider.all
  end

  def self.reflect_on_association(*args)
    # Nothing, cocoon need it
  end

  def build_service_provider
    sp                      = EasySamlServiceProvider.new
    sp.saml_server_settings = self
    sp
  end

  def service_providers_attributes
    # Nothing, rails need it
  end

  def service_providers_attributes=(attributes = {})
    @sp_to_save   = []
    @sp_to_delete = []

    attributes.each do |_, attrs|
      id               = attrs.delete('id')
      delete           = attrs.delete('_destroy').to_s.to_boolean
      service_provider = service_providers.detect { |sp| sp.id.to_s == id.to_s } if id.present?

      if delete
        @sp_to_delete << service_provider
      else
        service_provider            ||= build_service_provider
        service_provider.attributes = attrs
        @sp_to_save << service_provider
      end
    end
  end

  def save
    @sp_to_save.each(&:save) if @sp_to_save.present?
    @sp_to_delete.each(&:destroy) if @sp_to_delete.present?
  end

end
