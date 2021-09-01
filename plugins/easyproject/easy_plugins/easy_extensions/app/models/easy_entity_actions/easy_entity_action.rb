class EasyEntityAction < ActiveRecord::Base
  include Redmine::SafeAttributes
  include Rails.application.routes.url_helpers
  include EasyUtils::DateUtils

  belongs_to :project
  belongs_to :author, :class_name => 'User'
  belongs_to :execute_as_user, :class_name => 'User', :foreign_key => 'execute_as_user_id'

  has_many :histories, :class_name => 'EasyEntityActionHistory', :dependent => :destroy

  scope :active, lambda { where(:active => true) }
  scope :run_at, lambda { |time| where(["#{EasyEntityAction.table_name}.nextrun_at IS NULL OR #{EasyEntityAction.table_name}.nextrun_at <= ?", time]) }
  scope :run_now, lambda { run_at(Time.now) }

  set_associated_query_class EasyEntityActionQuery

  serialize :easy_query_settings, EasyExtensions::UltimateHashSerializer
  serialize :period_options, EasyExtensions::UltimateHashSerializer
  serialize :setup_actions, JSON

  store :settings, accessors: [:target_project_id], coder: JSON

  safe_attributes 'name', 'action_name', 'active', 'author_id', 'project_id', 'entity_type',
                  'entity_id', 'easy_query_settings', 'execute_as', 'execute_as_user_id',
                  'mail', 'mail_sender', 'mail_cc', 'mail_bcc', 'mail_subject', 'mail_html_body',
                  'repeatedly', 'period_options', 'use_journal', 'target_project_id', 'user_actions_query_params'
  safe_attributes 'type', if: ->(easy_entity_action, _user) { easy_entity_action.new_record? }

  class_attribute :registered_actions
  self.registered_actions = {}

  def self.map(&block)
    yield self
  end

  def self.disabled_sti_class
    EasyDisabledEntityAction
  end

  def self.add(klass_name, *action_names)
    registered_actions[klass_name] ||= Set.new
    registered_actions[klass_name].merge(action_names)
  end

  def self.default_url_options
    Mailer.default_url_options
  end

  def self.caption(klass_name = self.name)
    l("easy_entity_action.#{klass_name.underscore}.caption", default: klass_name.underscore)
  end

  def action_caption(action_name)
    l("easy_entity_action.#{self.class.name.underscore}.actions.#{action_name}", default: action_name)
  end

  def self.format_html_entity_name
    'easy_entity_action'
  end

  def self.css_icon
    'icon icon-workflow'
  end

  def action_names
    registered_actions[self.class.name]
  end

  def create_easy_query
    create_easy_query_from_associated_entity
  end

  def editable?(user = nil)
    user ||= User.current
    true
  end

  def visible?(user = nil)
    user ||= User.current
    true
  end

  def executable_user
    @executable_user ||= case self.execute_as
                         when 'author'
                           self.author
                         when 'user'
                           self.execute_as_user
                         end

    @executable_user || self.author || User.current
  end

  def execute_all
    ret_val = false

    self.executable_user.execute do
      query = create_easy_query_from_associated_entity

      if query
        entities = query.entities
        entities.each do |entity|

          ret_val = self.execute(entity)

        end
      end
    end

    ret_val
  end

  def execute(entity)
    return false if !entity

    if self.use_journal?
      entity.clear_current_journal if entity.respond_to?(:clear_current_journal)
      t = '<p>'
      t << l(:text_easy_entity_action_journal, link: "<a href='#{easy_entity_action_url(self)}'>#{self.name}</a>")
      t << '<p>'
      _journal = entity.init_journal(self.executable_user, t) if entity.respond_to?(:init_journal)
    end

    ret_status = do_action_on(entity) || false

    self.histories.create(entity: entity) if ret_status

    begin
      entity.save(validate: false)
    rescue ActiveRecord::StaleObjectError
      # do it next time
    end

    ret_status
  end

  def do_action_on(entity)
    # to override for custom action
    if can_user_define_actions? && setup_actions.is_a?(Hash) && !setup_actions.empty?
      cols = associated_entity_class.columns_hash
      setup_actions.each do |key, value|
        if (/date|timestamp/.match?(cols[key].sql_type)) && value.is_a?(Hash)
          value = get_date_range(nil, value['period'], value['from'], value['to'], value['period_days'], value['period_days_from'], value['period_days_to'])&.[] :to
        end

        entity.safe_attributes = { key => value }
      end
    end

  end

  def can_user_define_actions?
    false
  end

  def user_actions_query_params= params
    fields, values     = Array(params['fields']), Hash(params['values'])
    cols               = associated_entity_class.column_names
    self.setup_actions = values.inject({}) do |mem, (k, v)|
      if fields.include?(k) && cols.include?(k)
        # todo find better solution
        col_type = associated_entity_class.type_for_attribute(k)
        begin
          mem[k] = col_type.serialize(col_type.deserialize(v))
        rescue
          mem[k] = v
        end
      end
      mem
    end
  end

  def user_actions_to_query_params
    fields, operators = [], {}
    values            = (setup_actions || {}).inject({}) do |mem, (k, v)|
      fields << k
      if v.is_a?(Hash)
        operators[k] = 'date_period_1'
        mem[k]       = v
      else
        operators[k] = '='
        mem[k]       = v.to_s
      end
      mem
    end
    { 'set_filter' => 1, 'fields' => fields, 'operators' => operators, 'values' => values }
  end

  protected

  def create_easy_query_from_associated_entity
    query_class = associated_entity_class.try(:associated_query_class)
    return nil if !query_class

    query = create_easy_query_from_klass(query_class)
    query
  end

  def create_easy_query_from_klass(klass)
    query         = klass.new
    query.project = project
    query.from_params(easy_query_settings)

    if !self.repeatedly?
      query.add_additional_statement("NOT EXISTS(SELECT #{EasyEntityActionHistory.table_name}.id FROM #{EasyEntityActionHistory.table_name} WHERE #{EasyEntityActionHistory.table_name}.easy_entity_action_id = #{self.id} AND #{EasyEntityActionHistory.table_name}.entity_type = '#{self.associated_entity_class.name}' AND #{EasyEntityActionHistory.table_name}.entity_id = #{self.associated_entity_class.table_name}.id)")
    end

    query
  end

end
