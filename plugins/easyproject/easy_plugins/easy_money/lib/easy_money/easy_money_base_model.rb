module EasyMoney
  module EasyMoneyBaseModel

    cattr_accessor :money_entries

    def self.included(base)
      base.extend EasyMoney::EasyCurrencyRecalculateMixin
      self.money_entries ||= []
      self.money_entries << base

      base.class_eval do

        include Redmine::SafeAttributes

        belongs_to :project
        belongs_to :entity, :polymorphic => true
        belongs_to :easy_currency, foreign_key: :easy_currency_code, primary_key: :iso_code
        has_many :easy_external_synchronisations, :as => :entity, :dependent => :destroy

        scope :visible, ->(*args) { includes(:project).references(:project).where(Project.allowed_to_condition(User.current, :"easy_money_show_#{self.name_without_prefix}", *args)) }

        acts_as_customizable
        acts_as_attachable

        validates :entity, presence: true, if: proc { |e| e.new_record? || e.entity_id_changed? || e.entity_type_changed? }
        validates_length_of :name, :in => 1..255, :allow_nil => false
        validates_numericality_of :price1, :allow_nil => true
        validates_numericality_of :price2, :allow_nil => true
        validates_numericality_of :vat, :allow_nil => true

        before_save :update_project_id
        after_save :copy_related_entities_after_save, :if => Proc.new {|o| o.money_instance_was.present? }

        safe_attributes 'spent_on', 'name', 'description', 'price1', 'price2', 'vat', 'version_id'
        safe_attributes 'entity_type', 'entity_id', 'custom_field_values', 'custom_fields', 'tag_list'
        safe_attributes 'easy_currency_code'

        attr_accessor :money_instance_was

        include EasyPatch::Acts::Repeatable

        acts_as_easy_entity_attribute_map

        set_associated_query_class "#{self}Query".constantize

        def price1
          super || 0.0
        end

        if self.table_exists? && self.column_names.include?('price2')
          def price2
            super || 0.0
          end
        end

        def spent_on=(value)
          date = value.respond_to?(:call) ? value.call : value
          super date

          if spent_on.is_a?(Time)
            self.spent_on = spent_on.to_date
          end

          return unless self.class.column_names.include?('tyear')

          self.tyear = spent_on ? spent_on.year : nil
          self.tmonth = spent_on ? spent_on.month : nil
          self.tweek = spent_on ? Date.civil(spent_on.year, spent_on.month, spent_on.day).cweek : nil
          self.tday = spent_on ? spent_on.day : nil
        end

        def project
          super || project_from_entity
        end

        def project_from_entity
          self.entity.project if self.entity.respond_to?(:project)
        end

        def issue
          self.entity_type == 'Issue' ? self.entity : nil
        end

        def version
          self.entity_type == 'Version' ? self.entity : nil
        end

        def easy_crm_case
          self.entity_type == 'EasyCrmCase' ? self.entity : nil
        end

        def main_project
          self.project.root if self.project
        end

        def calculate_vat
          vat = (((self.price1 * 100.0) / self.price2) - 100.0).round(2)
          vat.finite? ? vat : 0.0
        end

        def entity_title
          self.entity.respond_to?(:subject) ? self.entity.subject : self.entity.send(:name)
        end

        def attachments_visible?(user=nil)
          visible?(user) || editable?(user)
        end

        def attachments_editable?(user=nil)
          editable?(user)
        end

        def attachments_deletable?(user=nil)
          editable?(user)
        end

        def recipients
          project.notified_users.select{|user| visible?(user) || editable?(user)}
        end

        def update_project_id
          self.project_id = project_from_entity.try(:id)
        end

        def easy_repeate_update_time_cols(time_vector, start_timepoint = nil, options={})
          self.spent_on = start_timepoint + time_vector
        end

        def copy_related_entities_after_save
          self.attachments = money_instance_was.attachments.map { |a| new_attachment = a.dup; new_attachment.easy_external_id = nil; new_attachment }
        end

        def to_s
          self.name
        end

        def editable_custom_fields
          visible_custom_field_values.map(&:custom_field).uniq
        end

        def editable?(user = nil)
          user ||= User.current
          user.allowed_to?(:"easy_money_manage_#{self.class.name_without_prefix}", self.project)
        end

        def visible?(user = nil)
          user ||= User.current
          user.allowed_to?(:"easy_money_show_#{self.class.name_without_prefix}", self.project)
        end

        def decorate(view_context)
          @decorate ||= EasyMoneyBaseModelDecorator.new(self, view_context)
        end

      end
    end

  end
end
