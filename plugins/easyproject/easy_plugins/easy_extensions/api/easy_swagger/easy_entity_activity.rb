module EasySwagger
  class Entity
    attr_accessor :id, :type, :name

    def initialize(id, type, name)
      self.id = id
      self.type = type
      self.name = name
    end
  end

  class EasyEntityActivity
    include EasySwagger::BaseModel
    swagger_me

    shared_scheme do
      relation 'category'
      relation 'author'

      property 'is_finished', type: 'boolean'
      property 'all_day', type: 'boolean'

      property 'start_time', type: 'string' do
        key :readOnly, true
        key :format, 'datetime'
      end

      property 'end_time', type: 'string' do
        key :readOnly, true
        key :format, 'datetime'
      end

      timestamps
      property 'description', type: 'string'

      property 'editable', type: 'boolean', value: ->(_context, activity) { activity.entity.editable? } do
        key :readOnly, true
      end
    end

    request_schema do
      property 'entity_id', type: 'integer'
      property 'entity_type', type: 'string'
      key :required, %w[entity_id, entity_type category_id]
    end

    response_schema do
      property 'entity', type: 'object', value: ->(_context, activity) { Entity.new(activity.entity.id, activity.entity_type, activity.entity.to_s) }, if: ->(activity) { activity.entity.visible? } do
        property 'id', type: 'integer'
        property 'type', type: 'string'
        property 'name', type: 'string' do
          key :readOnly, true
        end
      end

      property 'contact_attendees', type: "array", value: ->(_context, activity) { activity.easy_entity_activity_contacts }, if: ->(_activity) { ::User.current.allowed_to_globally?(:view_easy_contacts) } do
        items(schema_name: 'contact') do
          key :type, "object"
          property 'id', type: 'integer'
          property 'name', type: 'string'
        end
      end if Redmine::Plugin.installed?(:easy_contacts)
    
      property 'users_attendees', type: "array", value: ->(_context, activity) { activity.easy_entity_activity_users } do
        items(schema_name: 'user') do
          key :type, "object"
          property 'id', type: 'integer'
          property 'name', type: 'string'
        end
      end
    end
  end
end
