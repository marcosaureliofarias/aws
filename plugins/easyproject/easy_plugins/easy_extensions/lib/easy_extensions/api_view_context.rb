module EasyExtensions
  # This class fake view_context for render Redmine views, includes hooks and helpers methods
  # USAGE:
  # context = EasyExtensions::ApiViewContext.get_context
  # context.render @issue
  class ApiViewContext < MyController

    # @param [Symbol] context_for_format
    attr_writer :context_for_format

    # @param [Symbol] format should be `json` or `xml`
    # @return [EasyExtensions::ApiViewContext]
    def self.get_context(format: :json)
      r = ActionController::Renderer.for(MyController, 'action_dispatch.request.parameters' => { format: format })
      request = ActionDispatch::Request.new r.instance_variable_get(:@env)
      request.routes = _routes

      instance = new
      instance.set_request! request
      instance.set_response! make_response!(request)
      instance.context_for_format = format.to_sym
      instance
    end

    def details_for_lookup
      details = super
      details.merge(formats: [@context_for_format])
    end


  end
end
