module EasyMoney
  module EasyMoneyRelations
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_easy_money(options = {})

        has_one :expected_hours, :as => :entity, :class_name => 'EasyMoneyExpectedHours', :dependent => :destroy
        has_one :expected_payroll_expenses, :as => :entity, :class_name => 'EasyMoneyExpectedPayrollExpense', :dependent => :destroy

        has_many :expected_expenses, :as => :entity, :class_name => 'EasyMoneyExpectedExpense', :dependent => :destroy
        has_many :expected_revenues, :as => :entity, :class_name => 'EasyMoneyExpectedRevenue', :dependent => :destroy
        has_many :other_expenses, :as => :entity, :class_name => 'EasyMoneyOtherExpense', :dependent => :destroy
        has_many :other_revenues, :as => :entity, :class_name => 'EasyMoneyOtherRevenue', :dependent => :destroy
        has_many :travel_costs, :as => :entity, :class_name => 'EasyMoneyTravelCost', :dependent => :destroy
        has_many :travel_expenses, :as => :entity, :class_name => 'EasyMoneyTravelExpense', :dependent => :destroy
        has_many :easy_money_time_entry_expenses, :through => :time_entries

        before_save :update_project_on_related_easy_money_entities, :if => Proc.new {|o| o.respond_to?(:project_id) && o.project_id_changed?}

        scope :with_easy_money_entities, lambda {
          sql = ''
          conds = []
          (EasyMoney.easy_money_base_entities + [EasyMoneyExpectedHours]).each do |e|
            tbl = e.table_name
            conds << "EXISTS (SELECT * FROM #{tbl} WHERE #{self.table_name}.id = #{tbl}.entity_id AND #{tbl}.entity_type = '#{self.name}')"
          end
          sql << conds.join(' OR ')
          where(sql)
        }

        send :include, EasyMoney::EasyMoneyRelations::InstanceMethods
      end
    end

    module InstanceMethods
      def self.included(base)
        base.extend ClassMethods
      end

      def update_project_on_related_easy_money_entities
        EasyMoney.easy_money_base_entities.each do |easy_money_klass|
          easy_money_klass.where(entity_type: self.class.name, entity_id: self.id).update_all(project_id: self.project_id)
        end
        true
      end

      def copy_easy_money_entity(easy_money_entity)
        new_entity = easy_money_entity.dup
        new_entity.entity_id = self.id
        new_entity.save
        new_entity.custom_values = easy_money_entity.custom_values.map { |v| new_value = v.dup; new_value.easy_external_id = nil; new_value } if easy_money_entity.respond_to?(:custom_values) && easy_money_entity.custom_values.any?
        new_entity.attachments = easy_money_entity.attachments.map { |a| new_attachment = a.dup; new_attachment.easy_external_id = nil; new_attachment } if easy_money_entity.respond_to?(:attachments) && easy_money_entity.attachments.any?
      end

      def copy_easy_money(entity)
        project = entity.project
        settings = project.easy_money_settings
        if settings.show_expected?
          entity.expected_expenses.find_each(:batch_size => 50) { |expected_expense| copy_easy_money_entity(expected_expense) }
          entity.expected_revenues.find_each(:batch_size => 50) { |expected_revenue| copy_easy_money_entity(expected_revenue) }
        end

        entity.other_expenses.find_each(:batch_size => 50) { |other_expense| copy_easy_money_entity(other_expense) }
        entity.other_revenues.find_each(:batch_size => 50) { |other_revenue| copy_easy_money_entity(other_revenue) }

        entity.travel_costs.find_each(:batch_size => 50) { |travel_cost| copy_easy_money_entity(travel_cost) } if settings.use_travel_costs?
        entity.travel_expenses.find_each(:batch_size => 50) { |travel_expense| copy_easy_money_entity(travel_expense) } if settings.use_travel_expenses?

        if settings.expected_payroll_expense_type == 'hours'
          copy_easy_money_entity(entity.expected_hours) if entity.expected_hours
        end

        copy_easy_money_entity(entity.expected_payroll_expenses) if entity.expected_payroll_expenses
      end

      module ClassMethods
      end
    end
  end
end
ActiveRecord::Base.include(EasyMoney::EasyMoneyRelations)
