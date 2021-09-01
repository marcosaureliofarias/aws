module EasySwagger
  class EasyCrmCaseItem
    include EasySwagger::BaseModel
    swagger_me

    shared_scheme do
      property "easy_external_id"

      property "name", type: "string" do
        key :example, 'test 2'
        key :description, "Name"
      end
      property "description", type: "string" do
        key :example, '<p>xxxx</p>
'
        key :description, "Description"
      end
      property "total_price", type: "number" do
        key :example, 150
      end
      property "amount", type: "number" do
        key :example, 2
      end
      property "price_per_unit", type: "number" do
        key :example, 80
      end
      property "discount", type: "number" do
        key :example, 10
      end
      relation *%w[easy_crm_case]
    end

    request_schema do
      property "reorder_to_position", type: "number" do
        key :description, "Change position in list"
      end
    end

    response_schema do
      property "position", type: "number" do
        key :description, "Position in list"
      end
    end
  end
end