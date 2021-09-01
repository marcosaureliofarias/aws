class EasyDefaultQueryMapping < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :default_for_role, class_name: 'Role', foreign_key: 'role_id'
  belongs_to :easy_query

  safe_attributes 'role_id', 'entity_type', 'easy_query_id', 'position', 'reorder_to_position'

  scope :typed, lambda { |type| where(entity_type: type).order(:position) }

  acts_as_positioned

  validates :entity_type, :easy_query, presence: true

  before_save :ensure_query_columns

  def position_scope
    cond = "entity_type = '#{entity_type}' AND role_id IS NOT NULL"
    self.class.where(cond)
  end

  def position_scope_was
    prev = destroyed? ? entity_type_was : entity_type_before_last_save
    cond = "entity_type = '#{prev}' AND role_id IS NOT NULL"
    self.class.where(cond)
  end

  private

  def ensure_query_columns
    query = self.easy_query
    if query && query.column_names.empty?
      query.column_names = query.default_list_columns
      query.save
    end
  end
end
