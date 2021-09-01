# Used to dynamically generate and include a module in a controller.
#
# Defines before_actions, controller actions and other methods for
# authorizing, settings variables and rendering actions that are rendered as easy pages.
#
# @note routes have to be drawn separately in routes file
# @note be careful about other authorization methods on target controller interfering(e.g. authorize_global throwing 403)
# @note project-scoped pages are not supported
# @note mind the order of include <=> before_actions, custom page finder method needs to go before this to set @page
module EasyExtensions
  class EasyPageHandler

    def self.register_for(base, handler_params)
      base.include generate_module(base, handler_params)
    end

    # @param [Hash] handler_params
    # @option handler_params page_name    [String]     page_name to find EasyPage by
    # @option handler_params path         [Proc]       path to EasyPage show action
    # @option handler_params show_action  [Symbol]     name of controller action to handle EasyPage show
    # @option handler_params edit_action  [Symbol]     name of controller action to handle EasyPage edit
    # @option handler_params page_context [Proc, Hash] optional additional page_context parameters
    def self.generate_module(base, handler_params)
      Module.new do
        base.class_eval do
          const_set(:HANDLER_PARAMS, handler_params)

          before_action -> { find_easy_page_by(page_name: handler_params[:page_name]) },
                        only: [handler_params[:show_action], handler_params[:edit_action]],
                        if:   proc { @page.nil? }
          before_action :authorize_for_page_show, only: [handler_params[:show_action]]
          before_action :authorize_for_page_edit, only: [handler_params[:edit_action]]
        end

        # show action
        define_method(handler_params[:show_action]) do
          render_action_as_easy_page(@page, @page.user, entity, path_to_page, false, default_page_context.merge(additional_page_context(handler_params[:show_action])))
        end

        # edit action
        define_method(handler_params[:edit_action]) do
          render_action_as_easy_page(@page, @page.user, entity, path_to_page, true, additional_page_context(handler_params[:edit_action]))
        end

        private

        def allowed_to_page_show?(permission = nil)
          return @authorized_show unless @authorized_show.nil?

          authorize_condition = proc { User.current.allowed_to_globally?({ controller: params[:controller], action: self.class::HANDLER_PARAMS[:show_action].to_s }) }
          @authorized_show    = @page.visible?(permission: permission, authorized: authorize_condition)
        end

        def allowed_to_page_edit?(permission = nil)
          return @authorized unless @authorized.nil?

          authorize_condition = proc { User.current.allowed_to_globally?({ controller: params[:controller], action: self.class::HANDLER_PARAMS[:edit_action].to_s }) }
          @authorized         = @page.editable?(permission: permission, authorized: authorize_condition)
        end

        def path_to_page
          instance_eval(&self.class::HANDLER_PARAMS[:path])
        end

        def entity
          instance_eval(&self.class::HANDLER_PARAMS[:entity]) if self.class::HANDLER_PARAMS[:entity]
        end

        def default_page_context
          { params: params, page_editable: allowed_to_page_edit? }
        end

        def additional_page_context(action)
          return {} unless self.class::HANDLER_PARAMS[:page_context]&.has_key?([action])

          if self.class::HANDLER_PARAMS[:page_context][action].is_a?(Proc)
            instance_eval(&self.class::HANDLER_PARAMS[:page_context][action])
          else
            self.class::HANDLER_PARAMS[:page_context][action]
          end
        end

        def find_easy_page_by(query_params)
          render_404 unless (@page = EasyPage.find_by(query_params))
        end

        def authorize_for_page_show(permission = nil)
          render_403 unless allowed_to_page_show?(permission)
        end

        def authorize_for_page_edit(permission = nil)
          render_403 unless allowed_to_page_edit?(permission)
        end
      end
    end

  end
end
