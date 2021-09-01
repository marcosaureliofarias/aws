module EasyHelpdesk
  module EasyIssueQueryPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :initialize_available_filters, :easy_helpdesk
        alias_method_chain :initialize_available_columns, :easy_helpdesk
        alias_method_chain :extended_period_options, :easy_helpdesk
        alias_method_chain :columns_with_me, :easy_helpdesk

        def sql_for_easy_helpdesk_project_monthly_hours_field(field, operator, value)
          field_cond = sql_for_field(field, operator, value, EasyHelpdeskProject.table_name, 'monthly_hours')
          "#{Issue.table_name}.project_id IN (SELECT #{EasyHelpdeskProject.table_name}.project_id FROM #{EasyHelpdeskProject.table_name} WHERE #{field_cond})"
        end

        def sql_for_easy_helpdesk_maintained_field(field, operator, value)
          "#{(Array(value).include?('1')) ? '' : 'NOT '}EXISTS (SELECT ehp.id FROM #{EasyHelpdeskProject.table_name} ehp WHERE ehp.project_id = #{Issue.table_name}.project_id)"
        end

        def sql_for_easy_helpdesk_has_sla_field(field, operator, value)
          "#{Issue.table_name}.easy_helpdesk_project_sla_id IS #{(Array(value).include?('1')) ? 'NOT' : ''} NULL"
        end

        def sql_for_easy_time_to_solve_paused_field(field, operator, value)
          "#{Issue.table_name}.easy_time_to_solve_paused_at IS #{(Array(value).include?('1')) ? 'NOT' : ''} NULL"
        end

        def sql_for_easy_response_date_time_field(field, operator, value)
          db_field = 'easy_response_date_time'
          db_table = self.entity.table_name

          if operator =~ /date_period_([12])/
            if $1 == '1' && value[:period].to_s == 'all'
              "#{Issue.quoted_table_name}.#{db_field} = #{Issue.quoted_table_name}.created_on"
            else
              period_dates = self.get_date_range($1, value[:period], value[:from], value[:to], value[:period_days])
              self.date_clause(db_table, db_field, (period_dates[:from].nil? ? nil : period_dates[:from]), (period_dates[:to].nil? ? nil : period_dates[:to]), absolute_time: true, field: field)
            end
          else
            nil
          end
        end

        def sql_for_easy_due_date_time_field(field, operator, value)
          db_field = 'easy_due_date_time'
          db_table = self.entity.table_name

          if operator =~ /date_period_([12])/
            if $1 == '1' && value[:period].to_s == 'all'
              "#{Issue.quoted_table_name}.#{db_field} = #{Issue.quoted_table_name}.created_on"
            else
              period_dates = self.get_date_range($1, value[:period], value[:from], value[:to], value[:period_days])
              self.date_clause(db_table, db_field, (period_dates[:from].nil? ? nil : period_dates[:from]), (period_dates[:to].nil? ? nil : period_dates[:to]), absolute_time: true, field: field)
            end
          else
            nil
          end
        end

        def sql_for_has_easy_sla_event_field(field, operator, value)
          "#{(Array(value).include?('1')) ? '' : 'NOT '}EXISTS (SELECT ese.id FROM #{EasySlaEvent.table_name} ese WHERE ese.issue_id = #{Issue.table_name}.id)"
        end

        def before_sla_expires_date_clause(field, db_table, db_field, value, operator)
          user_now = User.current.user_time_in_zone.utc
          case operator
          when '='
            from = user_now + value[0].to_f.hours
            date_clause(db_table, db_field, from - 5.minutes, from + 5.minutes)
          when '>='
            date_clause(db_table, db_field, user_now + value[0].to_f.hours, nil)
          when '<='
            date_clause(db_table, db_field, nil, user_now + value[0].to_f.hours)
          when '><'
            from = user_now + value[0].to_f.hours
            to = user_now + value[1].to_f.hours
            date_clause(db_table, db_field, from, to)
          when '!*', '*'
            sql_for_field(db_field, operator, value, db_table, db_field, false)
          end
        end

        def sql_for_easy_helpdesk_time_to_response_field(field, operator, value)
          db_table = Issue.table_name
          db_field = 'easy_response_date_time'
          before_sla_expires_date_clause(field, db_table, db_field, value, operator)
        end

        def sql_for_easy_helpdesk_time_to_solve_field(field, operator, value)
          db_table = Issue.table_name
          db_field = 'easy_due_date_time'
          before_sla_expires_date_clause(field, db_table, db_field, value, operator)
        end

      end
    end

    module InstanceMethods

      def initialize_available_filters_with_easy_helpdesk
        initialize_available_filters_without_easy_helpdesk

        group = l(:easy_helpdesk_name)

        add_available_filter 'easy_email_to', {:type => :string, :group => group}
        add_available_filter 'easy_email_cc', {:type => :string, :group => group}
        add_available_filter 'easy_helpdesk_maintained', {:type => :boolean, :order => 1, :group => group, :name => l(:field_is_under_helpdesk)}
        add_available_filter 'easy_helpdesk_project_monthly_hours', {:type => :float, :order => 3, :group => group}
        add_available_filter 'easy_helpdesk_need_reaction', {:type => :boolean, :group => group, :label => :field_easy_helpdesk_need_reaction}
        add_principal_autocomplete_filter 'easy_helpdesk_ticket_owner_id', { attr_reader: true, attr_writer: true, group: group, label: :field_easy_helpdesk_ticket_owner, source_options: { include_groups: Setting.issue_group_assignment? || nil } }
        add_available_filter 'has_easy_sla_event', type: :boolean, group: group, name: l(:field_has_easy_sla_event)
        if Issue.display_easy_helpdesk_info? && User.current.allowed_to?(:view_easy_helpdesk_sla, project, global: true)
          @available_filters['easy_due_date_time'][:group] = group if @available_filters['easy_due_date_time']
          add_available_filter 'easy_helpdesk_has_sla', {:type => :boolean, :order => 2, :group => group, :name => l(:field_easy_helpdesk_has_sla)}
          add_available_filter 'easy_time_to_solve_paused', {:type => :boolean, :order => 4, :group => group, :name => l(:title_sla_waiting_for_client)}
          add_available_filter 'easy_response_date_time', {:type => :date_period, :time_column => true, :order => 15, :label => :field_hours_to_response, :group => group}
          add_available_filter 'easy_helpdesk_mailbox_username', { type: :string, order: 16, group: group, label: :label_easy_helpdesk_sender_mailbox_address }
          add_available_filter 'easy_helpdesk_time_to_response', type: :float, group: group, name: l(:'field_easy_helpdesk_hours_to_response_before_expired')
          add_available_filter 'easy_helpdesk_time_to_solve', type: :float, group: group, name: l(:'field_easy_helpdesk_hours_to_solve_before_expired')
        end
      end

      def initialize_available_columns_with_easy_helpdesk
        initialize_available_columns_without_easy_helpdesk

        group = l(:easy_helpdesk_name)
        @available_columns << EasyQueryColumn.new(:easy_email_to, :sortable => "#{Issue.table_name}.easy_email_to", :group => group)
        @available_columns << EasyQueryColumn.new(:easy_email_cc, :sortable => "#{Issue.table_name}.easy_email_cc", :group => group)
        @available_columns << EasyQueryColumn.new(:easy_helpdesk_project_monthly_hours, :numeric => true, :group => group)
        @available_columns << EasyQueryColumn.new(:easy_helpdesk_mailbox_username, caption: :label_easy_helpdesk_sender_mailbox_address, group: group, groupable: "#{Issue.table_name}.easy_helpdesk_mailbox_username")
        @available_columns << EasyQueryColumn.new(:easy_helpdesk_need_reaction, :caption => :field_easy_helpdesk_need_reaction, :sortable => "#{Issue.table_name}.easy_helpdesk_need_reaction", :group => group)
        @available_columns << EasyQueryColumn.new(:easy_helpdesk_ticket_owner, caption: :field_easy_helpdesk_ticket_owner, sortable: "#{Issue.table_name}.easy_helpdesk_ticket_owner_id", groupable: "#{Issue.table_name}.easy_helpdesk_ticket_owner_id", group: group, css_classes: 'assigned_to')
        if Issue.display_easy_helpdesk_info? && User.current.allowed_to?(:view_easy_helpdesk_sla, project, global: true)
          c = @available_columns.detect{|c| c.name == :easy_due_date_time_remaining}
          c.group = group if c # this column should be in a helpdesk group
          @available_columns << EasyQueryColumn.new(:easy_response_date_time_remaining, :sortable => "#{Issue.table_name}.easy_response_date_time", :caption => :field_hours_to_response, :group => group)

          @available_columns << EasyQueryColumn.new(:easy_due_date_time, :sortable => "#{Issue.table_name}.easy_due_date_time", :group => group, :caption => :field_date_to_solve)
          @available_columns << EasyQueryColumn.new(:easy_response_date_time, :sortable => "#{Issue.table_name}.easy_response_date_time", :group => group, :caption => :field_date_to_response)

        end

      end

      def extended_period_options_with_easy_helpdesk
        options = extended_period_options_without_easy_helpdesk
        options[:option_limit][:to_now] = ['easy_due_date_time', 'easy_response_date_time']
        options
      end

      def columns_with_me_with_easy_helpdesk
        columns_with_me_without_easy_helpdesk + ['easy_helpdesk_ticket_owner_id']
      end

    end

    module ClassMethods
    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'EasyIssueQuery', 'EasyHelpdesk::EasyIssueQueryPatch'

