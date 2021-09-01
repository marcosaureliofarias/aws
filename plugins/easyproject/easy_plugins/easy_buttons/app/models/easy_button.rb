require 'thread'

##
# EasyButton
#
# Entity custom buttons
#
# == Attributes:
#
# deleted::
#   Record will be deleted after launch application. Record is not destroyed
#   immediately because of synchronization across server workers.
#
# == Examples:
#
#   # On model:
#   class MyModel < ActiveRecord::Base
#     set_associated_query_class MyModelQuery
#     have_easy_buttons(edit_path: lambda { |entity|
#                         { controller: 'my_models', action: 'edit', id: entity.id }
#                       },
#                       update_path: lambda { |entity|
#                         { controller: 'my_models', action: 'update', id: entity.id }
#                       },
#                       params_name: 'my_model'
#                      )
#   end
#
#   # On view:
#   <%= render 'easy_buttons/buttons', entity: @my_model %>
#
#   # On query (you can use one parameter):
#   add_available_filter 'columns', {
#     attr_reader: true,
#     attr_writer: true
#   }
#
class EasyButton < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :author, class_name: 'User', foreign_key: 'author_id'

  safe_attributes 'name', 'active', 'color', 'conditions', 'actions',
                  'is_private', 'silent_mode', 'entity_note'
  safe_attributes 'entity_type', if: lambda { |eab, _| eab.new_record? }

  validates :name, :entity_type, presence: true

  before_save :set_values_before_create, if: -> { new_record? }
  before_save :reload_cache

  serialize :conditions, Hash
  serialize :actions, Hash

  set_associated_query_class EasyButtonQuery

  scope :visible, lambda { where(deleted: false) }
  scope :active, lambda { visible.where(active: true) }
  scope :visible_for_manage, lambda { |user = nil|
    user ||= User.current
    where(EasyButton.visible_conditions_for_manage(user))
  }
  scope :visible_for_execution, lambda { |user = nil|
    user ||= User.current

    if user.allowed_to_globally?(:execute_easy_buttons)
      active.where(EasyButton.visible_conditions(user, true))
    else
      where('1=0')
    end
  }
  scope :silent, lambda { where(silent_mode: true) }

  # Entity => EasyQuery
  mattr_accessor :registered_entities
  self.registered_entities = {}

  # EasyButton => Options
  mattr_accessor :instances
  self.instances = {}

  # Sync token
  mattr_accessor :last_reload_time
  self.last_reload_time = Time.at(0)

  # Mutex for reloading
  mattr_accessor :reload_mutex
  self.reload_mutex = Mutex.new


  # Register enity class and options
  # Required: :edit_path
  #           :update_path
  #           :params_name
  #           :query_class
  def self.register(entity_class, options)
    options[:query_class] ||= entity_class.try(:associated_query_class)

    [:edit_path, :update_path, :params_name, :query_class].each do |key|
      if options[key].blank?
        raise ArgumentError, "#{key} must be set"
      end
    end

    unless options[:query_class].ancestors.include?(EasyQuery)
      raise ArgumentError, 'Query class must be EasyQuery'
    end

    # Save class for creating a EasyQuery
    registered_entities[entity_class] = options
  end

  # This method shoudl be called only before starting a Server
  def self.remove_deleted
    EasyButton.where(deleted: true).delete_all
  end

  def self.reload_buttons
    reload_mutex.synchronize do

      # Some buttons was created, updated or deleted
      changed_buttons = EasyButton.where(['updated_at > ?', last_reload_time]).to_a
      changed_buttons.each(&:reload_button)

    end
  end

  def self.active_for(entity)
    buttons = instances.select do |instance, options|
      # Get buttons only for correct class
      unless options[:entity_class] == entity.class
        next
      end

      # Select only active
      instance.active_for?(entity)
    end

    buttons.keys
  end

  def self.get(id)
    instances.detect { |instance, _| instance.id == id.to_i }.try(:first)
  end

  def self.visible_conditions_for_manage(user = User.current)
    if user.admin?
      # manage all
      '1=1'
    elsif user.allowed_to_globally?(:manage_easy_buttons)
      # manage non-private and self-private
      EasyButton.visible_conditions(user, true).to_sql
    elsif user.allowed_to_globally?(:manage_own_easy_buttons)
      # manage self-private
      EasyButton.visible_conditions(user, false).to_sql
    else
      '1=0'
    end
  end

  def self.visible_conditions(user = User.current, global = false)
    eb = self.arel_table

    result = eb[:is_private].eq(true).and(eb[:author_id].eq(user.id))
    if global
      result = eb.grouping(result).or(eb[:is_private].eq(false))
    end
    result
  end

  def reload_button
    # I need to have admin rights (for all filters)
    current_admin      = User.current.admin
    User.current.admin = true

    # TODO: Move to self.reload_buttons ?
    if updated_at > last_reload_time
      self.last_reload_time = updated_at
    end

    # Don't care if there is or not
    remove_button

    # For callback
    if !active? || deleted?
      return true
    end

    # Reload conditions and actions
    reload_active_for
    reload_execute

    instances[self] = {
        entity_class: entity_class
    }
  ensure
    User.current.admin = current_admin
  end

  def remove_button
    instances.delete_if do |instance, _|
      instance.id == self.id
    end
  end

  def entity_class
    @entity_class ||= entity_type && entity_type.constantize
  rescue NameError
    nil
  end

  def entity_options
    registered_entities[entity_class] || {}
  end

  def conditions_query
    @conditions_query ||= new_entity_query(self.conditions)
  end

  def actions_query
    @actions_query ||= new_entity_query(self.actions)
  end

  # Filters from params
  # TODO: check query filters format
  def conditions=(params)
    return if entity_class.nil?
    super(parse_query_filters(params))
  end

  # Actions from params
  # TODO: check query filters format
  def actions=(params)
    return if entity_class.nil?
    super(parse_query_filters(params))
  end

  def editable?(user = User.current)
    user.allowed_to_globally?(:manage_easy_buttons) || (self.author_id == user.id && user.allowed_to_globally?(:manage_own_easy_buttons))
  end

  def visible?(user = User.current)
    user.allowed_to_globally?(:execute_easy_buttons)
  end

  def safe_destroy
    self.name    = '--- deleted ---'
    self.active  = false
    self.deleted = true

    save(validate: false)
  end

  # Fallback when method was not parsed
  # TODO: should be logged?
  def method_missing(name, *args, &block)
    case name
    when :execute
      return {}
    when :active_for?
      return false
    else
      super
    end
  end

  private

  def set_values_before_create
    self.author_id = User.current.id

    unless User.current.allowed_to_globally?(:manage_easy_buttons)
      self.is_private = true
    end
  end

  def new_entity_query(filters)
    query         = entity_options[:query_class].new
    query.filters = filters
    query
  end

  def parse_query_filters(params)
    query = new_entity_query({})
    query.add_filters(params['fields'], params['operators'], params['values'])
    query.filters
  end

  def reload_cache
    if conditions_changed? || is_private_changed? || new_record?
      # This ensure that button is active if there are no-filters
      result = [true]

      # Only for selected user (private button)
      result << "User.current.id == #{self.author_id}" if is_private?

      # Other conditions
      result.concat(EasyButtons::QueryCondition.parse(conditions_query))

      self.conditions_cache = result.join(' && ')
    end

    if actions_changed? || new_record?
      result = EasyButtons::QueryAction.parse(actions_query, entity_options)

      self.actions_cache = result
    end
  end

  def reload_active_for
    if respond_to?(:active_for?)
      instance_eval('undef :active_for?')
    end

    instance_eval <<-METHOD
        def active_for?(entity)
          #{self.conditions_cache}
        end
    METHOD
  end

  # This method return html form
  def reload_execute
    if respond_to?(:execute)
      instance_eval('undef :execute')
    end

    instance_eval <<-METHOD
        def execute(entity)
          return {} unless visible?

          #{EasyButtons::QueryAction::RESULT_VARIABLE_NAME} = {}

          #{self.actions_cache}

          data = {
            :#{entity_options[:params_name]} => #{EasyButtons::QueryAction::RESULT_VARIABLE_NAME}
          }
          execute_additional_data(data)

          data
        end
    METHOD
  end

  def instance_eval(*args)
    super
  rescue SyntaxError
    nil
  end

  def execute_additional_data(data)
    data[entity_options[:params_name].to_sym]['notes'] = entity_note if data[entity_options[:params_name].to_sym]
  end

end
