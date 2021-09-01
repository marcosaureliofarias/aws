module EasySwagger
  module BaseController
    extend ActiveSupport::Concern

    class_methods do

      cattr_accessor :use_same_request_response_models

      def entity=(name)
        @entity = name
      end

      def base_path=(name)
        @base_path = name
      end

      # @abstract guess entity name from controller
      def entity
        @entity || name.demodulize.remove("Controller").singularize
      end

      # @abstract base route to described controller
      def base_path
        @base_path || "/#{entity_name.pluralize}"
      end

      # @abstract name used in params
      def entity_name
        entity.underscore
      end

      # @abstract tag name used in spec docs
      def tag_name=(name)
        @tag_name = name
      end

      def tag_name
        @tag_name || entity_name.humanize
      end

      # Remove any base action
      # @param [String,Symbol] path of resource
      # @param [Symbol] action - method of resource [:get, :post, :put, :patch, :delete]
      def remove_action(path: "#{base_path}.{format}", action:)
        raise ArgumentError unless action.is_a?(Symbol)

        @swagger_path_node_map[path.to_sym].data.delete(action)
        @swagger_path_node_map.delete(path.to_sym) if @swagger_path_node_map[path.to_sym].data.blank?
      end

      # Add extra path or action on existing path
      # @param [String] path of resource
      def add_action(path, &block)
        unless path.start_with? "/"
          path = "#{base_path}/#{path}"
        end
        if @swagger_path_node_map[path]
          @swagger_path_node_map[path].instance_eval(&block)
        else
          swagger_path path, &block
        end
      end

      # @param [String] name of tag
      # @param [String] description
      # @return [String] tag name
      def add_tag(name: entity_name, description:)
        node = ApiDocsController.send(:_swagger_nodes)
        node[:root_node].tag name: name, description: description
        name
      end

      # In redmine some part of response is return only by specify `include` in request
      # this method handle `include` as a parameter to "index" and "show" actions
      # @param [Hash] includes is hash where `key` is name of "include" and `value` is its description
      # @example { group: "Allow return id and name of users groups", journals: "Allow return all journals with details"}
      def add_includes(**includes)
        return if includes.blank?

        index = path_node(:"#{base_path}.{format}")
        show = path_node(:"#{base_path}/{id}.{format}")

        parameter = parameter(**includes)
        show.data[:get].parameter &parameter
        index.data[:get].parameter &parameter
      end

      def add_includes_for_index(**includes)
        return if includes.blank?

        index = path_node(:"#{base_path}.{format}")
        parameter = parameter(**includes)
        index.data[:get].parameter &parameter
      end

      def add_includes_for_show(**includes)
        return if includes.blank?

        show = path_node(:"#{base_path}/{id}.{format}")
        parameter = parameter(**includes)
        show.data[:get].parameter &parameter
      end

      def parameter(**includes)
        return nil if includes.blank?

        proc do
          key :name, "include"
          key :description, "explicitly specify the associations you want to be included in the query result (separated by a comma)\n\n" + includes.map { |k, v| "* **#{k}** (#{v})" }.join("\n")
          key :in, "query"
          schema type: "array" do
            items do
              key :type, "string"
              key :enum, includes.keys
            end
          end
        end
      end

      def swagger_path(*_args, &_block)
        puts ActiveSupport::Deprecation.warn "Please call `swagger_me` method when including EasySwagger::BaseController into #{name}"
        swagger_me
      end

      # @param [String] entity is singular name of described model
      # @param [String] base_path in URL where is model located in app
      # @param [String] tag_name add own name of tag - for pretty output. By default its `entity_name`
      def swagger_me(entity: name.demodulize.remove("Controller").singularize, base_path: nil, redmine_api_responses: true, tag_name: nil)
        self.entity = entity
        self.base_path = base_path || "/#{entity_name.pluralize}"
        self.use_same_request_response_models = !redmine_api_responses
        self.tag_name = tag_name
        ::EasySwagger.register name
        include GeneralDefinitions
      end

      def api_response_entity_name
        use_same_request_response_models && entity || "#{entity}ApiResponse"
      end

      def api_request_entity_name
        use_same_request_response_models && entity || "#{entity}ApiRequest"
      end

      def path_node(name)
        @swagger_path_node_map[name.to_sym]
      end

    end

    module GeneralDefinitions
      extend ActiveSupport::Concern
      included do
        include Swagger::Blocks

        base = self

        swagger_path "#{base_path}.{format}" do
          operation :get do
            key :summary, "List of #{base.entity.pluralize}"
            key :description, "For filtering send parameter `set_filter=1` and specify filters"
            key :tags, [base.tag_name]
            extend EasySwagger::Parameters
            parameter do
              key :name, "easy_query_q"
              key :description, "free-text filter of current entity"
              key :in, "query"
              schema type: "string"
            end
            parameter do
              key :name, "set_filter"
              key :description, "enable filter through Easy Query"
              key :in, "query"
              schema type: "boolean"
            end
            parameter do
              key :name, "limit"
              key :description, "the number of items to be present in the response (default is 25, maximum is 100)"
              key :in, "query"
              schema type: "integer"
            end
            parameter do
              key :name, "offset"
              key :description, "the offset of the first object to retrieve"
              key :in, "query"
              schema type: "integer"
            end
            response 200 do
              key :description, "ok"
              EasySwagger.formats.each do |format|
                content format do
                  schema type: "object" do
                    xml name: base.entity_name.pluralize, wrapped: true
                    property "total_count", type: "number" do
                      key :example, 75
                      key :xml, attribute: true
                    end
                    property "offset", type: "number" do
                      key :example, 0
                      key :xml, attribute: true
                    end
                    property "limit", type: "number" do
                      key :example, 25
                      key :xml, attribute: true
                    end
                    property base.entity_name.pluralize, type: "array" do
                      items do
                        key "$ref", base.api_response_entity_name
                      end
                    end
                  end
                end
              end
            end
            response 401 do
              key :description, 'not authorized'
            end
          end
          operation :post do
            key :summary, "Create #{base.entity}"
            key :tags, [base.tag_name]
            extend EasySwagger::Parameters
            request_body do
              key :description, "Create #{base.entity}"
              key :required, true
              content "application/json" do
                schema do
                  key :type, "object"
                  property base.entity.underscore do
                    key "$ref", base.api_request_entity_name
                  end
                end
              end
              content "application/xml" do
                schema do
                  key "$ref", base.api_request_entity_name
                end
              end
            end
            extend EasySwagger::Responses::Basics
            extend EasySwagger::Responses::UnprocessableEntity
            response 201 do
              key :description, "created"
              content "application/json" do
                schema do
                  key :type, "object"
                  property base.entity.underscore do
                    key "$ref", base.api_response_entity_name
                  end
                end
              end
              content "application/xml" do
                schema do
                  key "$ref", base.api_response_entity_name
                end
              end
            end
          end
        end

        swagger_path "#{base_path}/{id}.{format}" do
          operation :get do
            key :summary, "Get #{base.entity}"
            key :tags, [base.tag_name]
            parameter do
              key :name, "id"
              key :in, "path"
              key :description, "ID of #{base.entity}"
              key :required, true
              schema type: "integer"
            end
            extend EasySwagger::Parameters
            extend EasySwagger::Responses::Basics
            response 200 do
              key :description, "detail of #{base.entity}"
              content "application/json" do
                schema do
                  key :type, "object"
                  property base.entity.underscore do
                    key "$ref", base.api_response_entity_name
                  end
                end
              end
              content "application/xml" do
                schema do
                  key "$ref", base.api_response_entity_name
                end
              end
            end
          end

          operation :put do
            key :summary, "Update #{base.entity}"
            key :tags, [base.tag_name]
            extend EasySwagger::Parameters
            parameter do
              key :name, "id"
              key :in, "path"
              key :description, "ID of #{base.entity}"
              key :required, true
              schema type: "integer"
            end
            request_body do
              key :description, "Update given #{base.entity}"
              key :required, true
              content "application/json" do
                schema type: "object" do
                  property base.entity_name do
                    key "$ref", base.api_request_entity_name
                  end
                end
              end
              content "application/xml" do
                schema do
                  key "$ref", base.api_response_entity_name
                end
              end
            end

            extend EasySwagger::Responses::Basics
            extend EasySwagger::Responses::UnprocessableEntity
            response 200 do
              key :description, "updated"
              content "application/json" do
                schema do
                  key :type, "object"
                  property base.entity_name do
                    key "$ref", base.api_response_entity_name
                  end
                end
              end
              content "application/xml" do
                schema do
                  key "$ref", base.api_response_entity_name
                end
              end
            end
          end

          operation :delete do
            key :summary, "Destroy #{base.entity}"
            key :tags, [base.tag_name]
            extend EasySwagger::Parameters
            parameter do
              key :name, "id"
              key :in, "path"
              key :description, "ID of #{base.entity}"
              key :required, true
              schema type: "integer"
            end

            extend EasySwagger::Responses::Basics
            response 204 do
              key :description, "ok"
            end
          end
        end
      end

    end
  end
end