class EasyMoneyPeriodicalEntity < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :entity, :polymorphic => true

  has_many :easy_money_periodical_entity_items, :dependent => :destroy

  scope :sorted_by_position, lambda {order("#{EasyMoneyPeriodicalEntity.table_name}.column_idx ASC, #{EasyMoneyPeriodicalEntity.table_name}.position ASC")}

  acts_as_tree
  acts_as_positioned
  acts_as_customizable

  before_save :update_project_id

  safe_attributes 'name', 'parent_id', 'position', 'column_idx', 'custom_field_values', 'custom_fields',
    :if => lambda {|empe, user| empe.new_record? || empe.editable?(user)}

  def position_scope
    cond = "#{EasyMoneyPeriodicalEntity.table_name}.entity_type = '#{self.entity_type}' AND #{EasyMoneyPeriodicalEntity.table_name}.entity_id = #{self.entity_id} AND #{EasyMoneyPeriodicalEntity.table_name}.column_idx = #{self.column_idx}"
    if self.parent_id
      cond << " AND #{EasyMoneyPeriodicalEntity.table_name}.parent_id = #{self.parent_id}"
    else
      cond << " AND #{EasyMoneyPeriodicalEntity.table_name}.parent_id IS NULL"
    end
    self.class.where(cond)
  end

  def position_scope_was
    method = destroyed? ? '_was' : '_before_last_save'
    entity_type_prev = send('entity_type' + method)
    entity_id_prev = send('entity_id' + method)
    column_idx_prev = send('column_idx' + method)
    parent_id_prev = send('parent_id' + method)

    cond = "#{EasyMoneyPeriodicalEntity.table_name}.entity_type = '#{entity_type_prev}' AND #{EasyMoneyPeriodicalEntity.table_name}.entity_id = #{entity_id_prev} AND #{EasyMoneyPeriodicalEntity.table_name}.column_idx = #{column_idx_prev}"
    if parent_id_prev
      cond << " AND #{EasyMoneyPeriodicalEntity.table_name}.parent_id = #{parent_id_prev}"
    else
      cond << " AND #{EasyMoneyPeriodicalEntity.table_name}.parent_id IS NULL"
    end
    self.class.where(cond)
  end

  def editable?(user = nil)
    return true
  end

  def visible?(user = nil)
    return true
  end

  def view_overview_item
    nil
  end

  def total_price
    self.easy_money_periodical_entity_items.sum(:price1).to_f
  end

  def current_price
    price_until(Date.today)
  end

  def price_until(date_period)
    self.easy_money_periodical_entity_items.until_period(date_period).sum(:price1).to_f
  end

  def edit_price_for_period(date_period)
    price_until(date_period)
  end

  def user_defined_items?
    true
  end

  def ensure_summable_parent_entity_items(period_date)
    empei = self.easy_money_periodical_entity_items.where(:period_date => period_date).first
    empei ||= self.easy_money_periodical_entity_items.build(:period_date => period_date, :author => User.current)

    empei.price1 = self.children.sum{|children_item| children_item.easy_money_periodical_entity_items.for_period(period_date).sum(:price1)}
    empei.price2 = self.children.sum{|children_item| children_item.easy_money_periodical_entity_items.for_period(period_date).sum(:price2)}

    empei.save

    return true
  end

  def recalculate_computed_values(period_date)
    return true
  end

  private

  def project_from_entity
    self.entity.project if self.entity.respond_to?(:project)
  end

  def update_project_id
    self.project_id = project_from_entity.try(:id)
  end

end
