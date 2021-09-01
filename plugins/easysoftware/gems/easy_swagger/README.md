# Swagger

https://github.com/fotinakis/swagger-blocks

## Usage

Generate swagger yaml file:
```ruby
rails r -e test "File.write('./doc/swagger.yaml', EasySwagger.to_yaml)"
```

### Your own CRUD controller
Create easy swagger class which represent controller of your entity (model) in `api/easy_swagger/` and include:
```ruby
include EasySwagger::BaseController
```
follow by `swagger_me` method which mean "describe me by swagger".
There are few options:
* `entity` = by default its demodulize name of controller. But if your entity is different, use it.
* `base_path` = path in uri. by default `/pluralize_entity_name`

note: see /api/easy_swagger/easy_settings_controller.rb

#### Extend base
If you need add more "actions", just define it based on swagger-blocks. Current endpoints are increased, new are added.

For add tag for your controller, use `add_tag` method from base.

#### Remove something from base
For remove action you need to know 2 parameters:
1. `path` - route path of action. By default its `entity_path` (its by default `entity.underscore.pluralize`)
2. `action` - symbol [:get, :post, :put, :patch, :delete]

for remove action from base, you can just call
```ruby
remove_action path: "/my_models.{format}", action: :get
```
note: Do not forget for `{format}` - all Easy API routes have it.

### Model
Create easy swagger model class in `api/easy_swagger/`. You need include `EasySwagger::BaseModel` and of course call.
```ruby
swagger_me
```
method.

In most of cases server response return different api model from model which describe data as input. Based on this fact
you need describe `response` scheme and `request` scheme. The most of field are shared - for this purpose this gem provides
DSL for `share_scheme` which sharing properties to `request_scheme` and `response_scheme` -> see example.

```ruby
module EasySwagger
  class MyModel
    include EasySwagger::BaseModel
    swagger_me

    shared_scheme do
      property "name"
      relation *%w[project tracker]
    end
    request_schema do
      key :required, %w[name]
    end
    response_schema do
      relation "author"
      attachments if: :serve_attachements? # this symbol will call on entity
      journals value: ->(context, entity) { context&.instance_variable_get(:@journals) }
      property "secret", if: ->(context, entity) { 1 + 1 == 3 }
      property "items", type: "array" do
        key :description, "Items list"
        items ref: EasySwagger::MyItem # this class describe MyItem class
      end

      timestamps
    end

  end
end
```

As you can see model DSL provide some extra methods and features.

#### `response_scheme`
all response scheme (when `response_scheme` block is used) contains property ID automatically
#### `timestamps`   
generate automatically `created_at` and `updated_at` properties
    * you can pass argument `legacy: true` = it change column name to old Redmine-like `created_on` and `updated_on`
#### `relation`
expect 1 - n columns which represent belongs_to relation, it generate in response property with ID and NAME,
in request it generate property with _id

> for example property `issue_id` in request and `issue` with `id type: integer`, `name type: string` in response
#### `custom_fields`
method automatically generate custom fields properties - request / response specific
#### `ref`
method add "$ref" reference to another API model. It expect full path in OpenAPI.
> Example:
    ```
    ref "easy_crm_case", EasySwagger::EasyCrmCase.response_schema_name
    ```

Follow currently exist models.

### Generate API from current model documentation

One of advantages define documentation by code is generate API from it.

in your `_show.api.rsb` you can call directly
```ruby
EasySwagger::MyModel.render_api(my_instance, self, local_assigns[:api])
```
See method documentation of optional arguments.

#### Direct JSON render

Render JSON directly from scheme:
```ruby
user = User.current
EasySwagger::MyModel.to_json(user)
```
#### Prepare Hash object

Maybe useful ruby hash of API schema with values of given object
```ruby
user = User.current
EasySwagger::MyModel.to_h(user)
```

## Use generator

Rys contains generator which prepared `Model` and `Controller` docs class.

```bash
rails g easy_swagger:doc MyModel
```

Generator try to guess request / response properties, based on safe attributes and columns.
