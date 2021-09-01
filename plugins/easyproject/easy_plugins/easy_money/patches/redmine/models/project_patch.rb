module EasyMoney
  module ProjectPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do
        has_many :easy_money_project_caches, class_name: 'EasyMoneyProjectCache', dependent: :delete_all

        has_many :easy_money_rates, dependent: :delete_all
        has_many :easy_money_settings_assoc, :class_name => "EasyMoneySettings", :foreign_key => "project_id", :dependent => :destroy

        acts_as_easy_money

        has_many :easy_money_periodical_entities, :as => :entity, :class_name => 'EasyMoneyPeriodicalEntity', :dependent => :destroy

        scope :travel_costs_enabled, -> { with_easy_money_setting('use_travel_costs', '1') }
        scope :travel_expenses_enabled, -> { with_easy_money_setting('use_travel_expenses', '1') }

        scope :with_easy_money_setting, -> setting_name, setting_value do
          project_table = Project.arel_table
          project_easy_money_settings_table = EasyMoneySettings.arel_table.alias('project_easy_money_settings')
          global_easy_money_settings_table = EasyMoneySettings.arel_table.alias('global_easy_money_settings')

          select_manager = Arel::SelectManager.new(project_table).tap do |manager|
            manager.join(project_easy_money_settings_table, Arel::Nodes::OuterJoin).on(
                project_easy_money_settings_table[:name].eq(setting_name)
                    .and(project_easy_money_settings_table[:project_id].eq project_table[:id])
            )

            manager.join(global_easy_money_settings_table, Arel::Nodes::OuterJoin).on(
                global_easy_money_settings_table[:name].eq(setting_name)
                    .and(global_easy_money_settings_table[:project_id].eq nil)
            )

            manager.where Arel::Nodes::NamedFunction.new('COALESCE', [project_easy_money_settings_table[:value], global_easy_money_settings_table[:value]]).eq(setting_value)

            manager.projections << project_table[:id]
          end

          where(project_table[:id].in(select_manager))
        end

        after_save :copy_easy_money_rate_priority

        attr_accessor :inherit_easy_money_settings

        # alias_method_chain :after_parent_changed, :easy_money

        safe_attributes 'inherit_easy_money_settings',
          :if => lambda {|project, user| project.new_record? }

        def self.easy_money_setting_condition(scope, setting, value = '1')
          scope.with_easy_money_setting(setting, value)
        end

        def easy_money(easy_currency_code = nil)
          @easy_money ||= EasyMoneyProject.new(self, easy_currency_code || self.easy_currency_code) if module_enabled?(:easy_money)
        end

        def easy_money_settings
          @easy_money_settings ||= EasyMoney::SettingsResolver.new((EasyMoneySettings.global_settings_names + EasyMoneySettings.project_settings_names), self) if module_enabled?(:easy_money)
        end

        def easy_money_active_rate_types
          EasyMoneyRateType.rate_type_cache.select{|r| self.easy_money_settings.show_rate?(r.name)}
        end

        def copy_easy_money_settings_from_parent
          if inherit_easy_money_settings && module_enabled?(:easy_money) && parent && parent.module_enabled?(:easy_money)
            # clean everything already set, then copy values from #parent
            EasyMoneySettings.where(:project_id => self).destroy_all
            EasyMoneySettings.copy_to(parent, self)
            EasyMoneyRatePriority.rate_priorities_by_project(self).delete_all
            EasyMoneyRatePriority.rate_priorities_by_project(parent).copy_to(self)
            self.easy_money_rates.delete_all
            EasyMoneyRate.copy_to(parent, self)
          end
        end

        # called from entity_bulk_update - monthly closing
        def recalculate_easy_money_periodical_entities(period_date = nil)
          period_date ||= Date.today

          recalculate_summable_parent_entity_items(period_date)
          recalculate_easy_money_periodical_entity_computed_values(period_date)
        end

        def recalculate_summable_parent_entity_items(period_date = nil)
          period_date ||= Date.today

          self.easy_money_periodical_entities.each do |entity|
            next if entity.user_defined_items?
            next if entity.children.empty?

            entity.ensure_summable_parent_entity_items(period_date)
          end
        end

        # called after each item saved/deleted
        def recalculate_easy_money_periodical_entity_computed_values(period_date = nil)
          period_date ||= Date.today

          self.easy_money_periodical_entities.each do |entity|
            next if entity.user_defined_items?

            entity.recalculate_computed_values(period_date)
          end
        end

        def empe_price_column(original_price_column, options = {})
          if options[:query] && options[:query].easy_currency_code.present?
            "#{original_price_column}_#{options[:query].easy_currency_code}".to_sym
          else
            original_price_column
          end
        end

        def empe_price_sum(array, original_price_column, options = {})
          price_column = empe_price_column(original_price_column, options).to_s
          array.sum{|element| element.attributes[price_column] || 0 }
        end

        def easy_money_visible?(user=User.current)
          actions = %i[
            easy_money_show_expected_revenue
            easy_money_show_expected_payroll_expense
            easy_money_show_expected_expense
            easy_money_show_expected_profit
            easy_money_show_expected_payroll_expense
            easy_money_show_other_revenue
            easy_money_show_time_entry_expenses
            easy_money_show_other_expense
            easy_money_show_other_profit
            easy_money_show_time_entry_expenses
            easy_money_show_travel_cost
            easy_money_show_travel_expens
          ]
          user.allowed_to_at_least_one_action?(actions, self)
        end

        def easy_money_editable?(user=User.current)
          actions = %i[
            easy_money_manage_expected_revenue
            easy_money_manage_expected_payroll_expense
            easy_money_manage_expected_expense
            easy_money_manage_expected_payroll_expense
            easy_money_manage_other_revenue
            easy_money_manage_travel_cost
            easy_money_manage_travel_expens
          ]
          user.allowed_to_at_least_one_action?(actions, self)
        end

        private

        def copy_easy_money_rate_priority
          mod = self.module_enabled?(:easy_money)

          if mod && EasyMoneyRatePriority.rate_priorities_by_project(self).blank?
            EasyMoneyRatePriority.rate_priorities_by_project(nil).copy_to(self)
          end
        end

        def copy_easy_money(project)
          if module_enabled?(:easy_money) && project && project.module_enabled?(:easy_money)
            EasyMoneySettings.where(:project_id => self.id).destroy_all
            EasyMoneySettings.copy_to(project, self)

            EasyMoneyRate.where(:project_id => self.id).destroy_all
            EasyMoneyRate.copy_to(project, self)

            EasyMoneyRatePriority.rate_priorities_by_project(project).copy_to(self)
            EasyMoneyTimeEntryExpense.update_project_time_entry_expenses(self)
            super
          end
        end

      end
    end

    module InstanceMethods

      # def after_parent_changed_with_easy_money(parent_was)
      #   after_parent_changed_without_easy_money(parent_was)
      #   copy_easy_money_settings_from_parent
      # end

      #      def easy_money_expected_revenue
      #        self.expected_revenue.price unless self.expected_revenue.nil?
      #      end
      #
      #      def easy_money_expected_revenue=(value)
      #        unless (self.id.blank?)
      #          e = self.expected_revenue || EasyMoneyExpectedRevenue.new(:entity_type => 'Project', :entity_id => self.id)
      #          e.price = value.blank? ? 0.0 : value
      #          e.save!
      #        end
      #      end
      #
      #      def easy_money_expected_expense
      #        self.expected_expense.price unless self.expected_expense.nil?
      #      end
      #
      #      def easy_money_expected_expense=(value)
      #        unless (self.id.blank?)
      #          e = self.expected_expense || EasyMoneyExpectedExpense.new(:entity_type => 'Project', :entity_id => self.id)
      #          e.price = value.blank? ? 0.0 : value
      #          e.save!
      #        end
      #      end
      #
      #      def easy_money_expected_hours
      #        self.expected_hours.hours unless self.expected_hours.nil?
      #      end
      #
      #      def easy_money_expected_hours=(value)
      #        unless (self.id.blank?)
      #          e = self.expected_hours || EasyMoneyExpectedHours.new(:entity_type => 'Project', :entity_id => self.id)
      #          e.hours = value.blank? ? 0 : value
      #          e.save!
      #        end
      #      end
    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Project', 'EasyMoney::ProjectPatch'
