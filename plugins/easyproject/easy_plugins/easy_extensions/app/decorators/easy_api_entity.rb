class EasyApiEntity
  include ApplicationHelper
  include Rails.application.routes.url_helpers

  class_attribute :registered_subclasses
  self.registered_subclasses = {}

  attr_accessor :included_hash

  def self.register(api_entity_class)
    registered_subclasses[api_entity_class.entity_class] = api_entity_class if registered_subclasses[api_entity_class].nil?
  end

  def self.find(entity_class)
    registered_subclasses[entity_class]
  end

  def initialize(entity, includes = [])
    @includes      = includes || []
    @entity        = entity
    @included_hash = {}
  end

  def include_in_api_response?(key)
    @includes.include?(key.to_s)
  end

  def merge(hash)
    @included_hash.merge!(hash)
    self
  end

  def to_xml
    build(:xml).output
  end

  def to_json
    build(:json).__to_json
  end

  def params
    {
        format: @format
    }
  end

  protected

  def build_api!(_app)
    raise NotImplementedError, "Entity doesn't define structure for decorator"
  end

  def self.entity_class
    raise NotImplementedError, "Entity doesn't define entity class for decorator"
  end

  private

  def build(build_type)
    @format = build_type.to_s

    case build_type.to_s
    when 'xml'
      app = Redmine::Views::Builders::Xml.new(nil, nil)
    when 'json'
      app = EasyExtensions::Views::Builders::LocalJson.new
    else
      raise ArgumentError
    end
    build_api!(app)
    add_included_hash!(app)
    app
  end

  def add_included_hash!(app)
    @included_hash.each do |key, val|
      app.__send__(key, val)
    end
  end

  def renderer
    ::EasyExtensions::ApiViewContext.get_context(format: @format)
  end

end
