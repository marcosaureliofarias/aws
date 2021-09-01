# frozen_string_literal: true

##
# This class is resolving permission for field not for a object
#
# @example Resolve a single permission
#
#   instance = MyModel.first
#
#   MyResolver.visible?(instance, :author)
#   MyResolver.editable?(instance, :author)
#
# @example Resolve multiple permissions
#
#   instance = MyModel.first
#   user = User.first
#   project = Project.first
#
#   resolver = MyResolver.resolver_for(instance, user: user, project: project)
#
#   resolver.visible?(instance, :author)
#   resolver.visible?(instance, :assignee)
#   resolver.editable?(instance, :author)
#
# @example Register resolver for specific model
#
#   class MyResolver < PermissionResolver
#     register_for 'MyModel'
#   end
#
# @example Resolve permission via if condition
#
#   class MyResolver
#     def resolve_visibility(key)
#       case key
#       when :author
#         User.current.logged?
#       end
#     end
#
#     def resolve_editability(key)
#       case key
#       when :author
#         User.current.allowed_to?(:view_author, project)
#       end
#     end
#   end
#
# @example Resolve permission via methods
#
#   class MyResolver
#     def author_visible
#       User.current.logged?
#     end
#
#     def author_editable
#       User.current.allowed_to?(:view_author, project)
#     end
#   end
#
# @example Resolve permissions via a mapper
#
#   class MyResolver
#     map_visibility(:author) do
#       User.current.logged?
#     end
#
#     map_editability(:author) do
#       User.current.allowed_to?(:view_author, project)
#     end
#   end
#
class PermissionResolver

  # Registered model/class and theirs resolvers
  mattr_accessor :registered, default: {}

  # Another way how to define key condition
  # { key => { visible: Proc, editable: Proc } }
  class_attribute :keys_mapper, default: Hash.new { |hash, key| hash[key] = {} }

  attr_reader :object, :project, :user

  # @param object_name [String] Register current class for specific model
  def self.register_for(object_name)
    registered[object_name] = self
  end

  # @param object [Object] class or instance
  def self.resolver_for(object, project: nil, user: nil)
    case object
    when String
      resolver_klass = registered[object.classify]
    when Class
      resolver_klass = registered[object.name]
    else
      resolver_klass = registered[object.class.name]
    end

    if resolver_klass.nil?
      resolver_klass = PermissionResolvers::AllPermitted
    end

    resolver_klass.new(object, project: project, user: user)
  end

  def self.visible?(object, key, project: nil, user: nil)
    resolver_for(object, project: project, user: user).visible?(key)
  end

  def self.editable?(object, key, project: nil, user: nil)
    resolver_for(object, project: project, user: user).editable?(key)
  end

  # See an class example for more details
  def self.map_visibility(key, &block)
    keys_mapper[key.to_sym][:visible] = block
  end

  # See an class example for more details
  def self.map_editability(key, &block)
    keys_mapper[key.to_sym][:editable] = block
  end

  def initialize(object, project: nil, user: nil)
    @object  = object
    @project = project
    @user    = user || User.current
  end

  def visible?(key)
    key = key.to_sym

    result =
      if respond_to?("#{key}_visible")
        send("#{key}_visible")
      elsif condition = keys_mapper.dig(key, :visible)
        instance_eval(&condition)
      else
        resolve_visibility(key.to_sym)
      end

    if result.nil?
      true
    else
      result
    end
  end

  def editable?(key)
    key = key.to_sym

    result =
      if respond_to?("#{key}_editable")
        send("#{key}_editable")
      elsif condition = keys_mapper.dig(key, :editable)
        instance_eval(&condition)
      else
        resolve_editability(key.to_sym)
      end

    if result.nil?
      true
    else
      result
    end
  end

  # Should retun true/false
  # Nil represent "unknow key"
  def resolve_visibility(key)
    true
  end

  # Should retun true/false
  # Nil represent "unknow key"
  def resolve_editability(key)
    true
  end

end

require 'easy_extensions/permission_resolvers/all_permitted'
require 'easy_extensions/permission_resolvers/project'
require 'easy_extensions/permission_resolvers/issue'
require 'easy_extensions/permission_resolvers/user'
