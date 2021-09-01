class EasyIntegrationsController < Easy::Redmine::BasicController

  self.entity_class = EasyIntegration

  menu_item :easy_integrations

  layout 'admin'

  def index
  end

  def settings
    @easy_integrations = EasyIntegration.where(slug: params[:slug]).group_by(&:entity_klass)
  end

end
