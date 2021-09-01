# frozen_string_literal: true

module EasyExtensions
  ##
  # Work with page module setting as with a object
  #
  # @example
  #
  #   <% module_form = EasyExtensions::PageModuleFormObject.new(page_module, project: @project) %>
  #   <%= form_for(module_form, builder: EasyExtensions::PageModuleFormObject::FormBuilder) do |form| %>
  #
  #     <% # Save it to the `page_module.settings['title']` %>
  #     <%= form.label :title %>
  #     <%= form.text_field :title %>
  #
  #     <%= form.fields_for :config do |config_form| %>
  #       <% # Save it to the `page_module.settings['config']['number']` %>
  #       <%= config_form.label :number %>
  #       <%= config_form.text_field :number %>
  #     <% end %>
  #
  #   <% end %>
  #
  class PageModuleFormObject

    class FormBuilder < ActionView::Helpers::FormBuilder

      def fields_for(record_name, record_object = nil, fields_options = {}, &block)
        record_object = object.clone_with_key(record_name)
        super
      end

    end

    attr_reader :page_module, :project, :keys

    def initialize(page_module, project: nil, keys: [])
      @page_module = page_module
      @project     = project
      @keys        = keys.map(&:to_s)
    end

    def clone_with_key(key)
      self.class.new(page_module, project: project, keys: (keys + [key]))
    end

    def persisted?
      true
    end

    def to_model
      self
    end

    def to_key
    end

    def model_name
      @model_name ||= ActiveModel::Name.new(EasyPageZoneModule, nil, page_module.module_name)
    end

    def current_settings
      page_module.settings.dig(*keys)
    end

    def method_missing(name, *args)
      page_module.settings.dig(*keys, name.to_s)
    end

  end
end
