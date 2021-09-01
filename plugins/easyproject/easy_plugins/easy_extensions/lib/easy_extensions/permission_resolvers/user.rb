# frozen_string_literal: true

module PermissionResolvers
  class User < PermissionResolver
    register_for 'User'
  end
end
