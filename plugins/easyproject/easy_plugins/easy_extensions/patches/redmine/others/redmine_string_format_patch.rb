module EasyPatch
  module StringFormatPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def group_statement(custom_field)
          Arel.sql "COALESCE(#{join_alias custom_field}.value, '')"
        end

      end
    end

    module InstanceMethods
    end

  end
end
