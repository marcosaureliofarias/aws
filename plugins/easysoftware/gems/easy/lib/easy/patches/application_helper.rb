module Easy
  module Patches
    module ApplicationHelper
      extend ActiveSupport::Concern

      included do

        def entity_form_with(entity, options = {}, html_options = {}, &block)
          form_with({ model: entity,
                      url:   polymorphic_path(entity.to_route),
                      data:  { remote: request.xhr? },
                      scope: entity.class.base_class.model_name.param_key,
                      html:  { class: '', id: "#{entity.class.base_class.model_name.param_key}_form" }.merge(html_options) }.merge(options),
                    &block)
        end

      end
    end
  end
end
