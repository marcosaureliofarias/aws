module EasySwagger
  class EasyKnowledgeStory
    include EasySwagger::BaseModel
    swagger_me

    shared_scheme do
      property 'name' do
        key :example, 'Please read me'
      end

      property "entity_type" do
        key :type, "string"
        key :example, "Issue"
      end

      property "entity_id", type: "integer"

      property 'description' do
        key :example, ''
      end

      custom_fields
    end

    request_schema do
      property 'author_id' do
        key :type, 'integer'
      end

      property "easy_knowledge_category_ids", type: "array" do
        key :description, "IDs of categories"
        items do
          key :type, "integer"
        end
      end

      property "references_by_ids", type: "array" do
        key :description, "IDs of categories"
        items do
          key :type, "integer"
        end
      end

      property "tag_list", type: "array" do
        key :description, "Tags"
        items do
          key :type, "string"
        end
      end
    end

    response_schema do
      property "author" do
        key :title, "User"
        key :type, "object"
        property "id", type: "integer"
        property "name"
      end

      property 'references' do
        key :type, "array"
        key :readOnly, true
        items do
          key :title, 'EasyKnowledgeStory'
          key :type, 'object'
          key :readOnly, true
          property "id", type: "integer"
          property "name", type: "string"
          property "entity_id", type: "integer"
          property "entity_type", type: "string"
          property "storyviews", type: "integer"
          property "author" do
            key :title, "User"
            key :type, "object"
            property "id", type: "integer"
            property "name"
          end
          property "description", type: "string"
        end
      end

      property "tags" do
        key :type, "array"
        key :readOnly, true
        items do
          key :title, "Tag"
          key :type, "object"
          key :readOnly, true
          property "id", type: "integer"
          property "name", type: "string"
        end
      end

      property 'storyviews' do
        key :type, 'Integer'
        key :example, 1
      end

      attachments
      journals
      timestamps legacy: true
    end

  end
end