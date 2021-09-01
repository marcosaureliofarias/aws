Rys::Patcher.add('ApplicationHelper') do

  apply_if_plugins :easy_extensions

  included do

    def easy_breadcrumb(*args)
      breadcrumb(*args) unless request.xhr?
    end

    def render_index_view(entity, options = {})
      render_inheritable_view(entity, "index", options)
    end

    def render_show_view(entity, options = {})
      render_inheritable_view(entity, "show", options)
    end

    def render_partial_show_view(entity, options = {})
      options[:locals]          ||= {}
      options[:locals][:entity] ||= entity
      render_inheritable_view(entity, "_show", options)
    end

    def render_new_view(entity, options = {})
      render_inheritable_view(entity, "new", options)
    end

    def render_edit_view(entity, options = {})
      render_inheritable_view(entity, "edit", options)
    end

    def render_form_view(entity, options = {})
      options[:locals]          ||= {}
      options[:locals][:entity] ||= entity
      render_inheritable_view(entity, "_form", options)
    end

    def form_container_id(entity)
      @entity.class.base_class.model_name.param_key + "_form_container"
    end

    private

    def render_inheritable_view(entity, view_name, options = {})
      collection    = ActiveSupport::Inflector.tableize(entity.class.name)
      partial       = false
      expected_path = "#{collection}/#{view_name}"
      fallback_path = "easy/redmine/basic/#{view_name}"
      opts          = { formats: [:html] }.merge(options || {})

      if view_name.start_with?("_")
        partial   = true
        view_name = view_name[1..-1]
      end

      if lookup_context.exists?(view_name, collection, partial)
        render({ template: expected_path }.merge(opts))
      elsif lookup_context.exists?(view_name, "easy/redmine/basic", partial)
        Rails.logger.debug "Cannot find expected path at \"#{expected_path}\", rendering fallback at \"#{fallback_path}\""
        render({ template: fallback_path }.merge(opts))
      else
        raise ActionView::MissingTemplate.new([expected_path, fallback_path], view_name, collection, partial, opts)
      end
    end

  end

end
