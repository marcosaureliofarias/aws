# frozen_string_literal: true

module PermissionResolvers
  class AllPermitted < PermissionResolver

    def self.visible?(*)
      true
    end

    def self.editable?(*)
      true
    end

    def visible?(*)
      true
    end

    def editable?(*)
      true
    end

    def resolve_visibility(*)
      true
    end

    def resolve_editability(*)
      true
    end

  end
end
