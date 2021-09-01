class ContextMenuResolver
  include Rails.application.routes.url_helpers
  include ApplicationHelper

  # Registered query and its resolver
  mattr_accessor :registered, default: {}
  # Registered entity class
  mattr_accessor :entity_klass

  attr_reader :entities, :user

  attr_accessor :items

  # @param object_name [String] Register current class for specific query
  def self.register_for(object_name)
    registered[object_name] = self
  end

  # @param object [EasyQuery] query class
  def self.items_for(type, ids, user: nil, options: {})
    return [] unless ::EasyQuery.registered_subclasses.include?(type)

    resolver_klass = registered[type]
    return [] if resolver_klass.nil?

    entities = entity_klass.constantize.where(id: ids)
    return [] if entities.empty?

    resolver = resolver_klass.new(entities, user, options)
    resolver.set_environment
    resolver.init_allowed_items
    resolver.items
  end

  def initialize(entities, user, options = {})
    @entities = entities
    @user = user || User.current
    @options = options
    @items = []
  end

  # set your working environment (optional)
  def set_environment
  end

  def init_allowed_items
    registered_items.each do |category, items|
      on_category(category) do
        items.each do |name|
          init_item(name)
        end
      end
    end

    on_category('custom_fields') do
      init_custom_field_items
    end
  end

  private

  # register all items for each subclass
  def registered_items
    raise NotImplementedError
  end

  # define item visibility
  def item_allowed?(name)
    raise NotImplementedError
  end

  def init_item(name)
    send "init_#{name}_item" if item_allowed?(name)
  end

  # define editable custom fields
  def init_custom_field_items
  end

  def on_category(category)
    old_category      = @current_category
    @current_category = category
    yield
  ensure
    @current_category = old_category
  end

  def add_url_item(attr)
    items << ::ContextMenuResolvers::ItemTypes::Url.new(default_item_attr.merge(attr))
  end

  def add_shortcut_item(attr)
    items << ::ContextMenuResolvers::ItemTypes::Shortcut.new(default_item_attr.merge(attr))
  end

  def add_list_item(attr)
    items << ::ContextMenuResolvers::ItemTypes::List.new(default_item_attr.merge(attr))
  end

  def add_autocomplete_item(attr)
    items << ::ContextMenuResolvers::ItemTypes::Autocomplete.new(default_item_attr.merge(attr))
  end

  def add_modal_item(attr)
    items << ::ContextMenuResolvers::ItemTypes::Modal.new(default_item_attr.merge(attr))
  end

  def add_custom_field_item(field, attr = {})
    attributes = { **default_item_attr, name: field.name, custom_field_id: field.id, url_prop: :custom_field_values, **attr }
    items << ::ContextMenuResolvers::ItemTypes::CustomField.new(attributes)
  end

  def default_item_attr
    { entity_name: self.class.entity_klass.underscore, category: @current_category }
  end

  def build_possible_value(key, value)
    { key: key, value: value }
  end

end

require 'easy_extensions/context_menu_resolvers/item_types/base'
Dir[File.dirname(__FILE__) + '/context_menu_resolvers/item_types/*.rb'].each { |file| require_dependency file }
Dir[File.dirname(__FILE__) + '/context_menu_resolvers/*.rb'].each { |file| require_dependency file }
