module EasyPatch
  module IntFormatPatch

    def self.included(base)
      base.class_eval do
        def order_statement(custom_field)
          "CAST(CASE #{join_alias custom_field}.value WHEN '' THEN '0' ELSE #{join_alias custom_field}.value END AS decimal(30,0))"
        end
      end
    end
  end
end
