module EasyGraphql
  module Types
    class EasyCurrency < Base

      field :id, ID, null: false
      field :name, String, null: false
      field :iso_code, String, null: true
      field :symbol, String, null: true
      field :activated, Boolean, null: true
      field :is_default, Boolean, null: true
      field :digits_after_decimal_separator, Int, null: true

    end
  end
end
