module EasyPatch
  module CustomFieldPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
      base.include(Redmine::SafeAttributes)

      base.class_eval do

        default_scope { column_names.include?('disabled') ? where(:disabled => false) : all }

        belongs_to :easy_group, class_name: 'EasyCustomFieldGroup', foreign_key: 'easy_group_id'
        has_many :mapping_fields, :class_name => 'CustomFieldMapping', :foreign_key => 'custom_field_id', :dependent => :destroy

        scope :for_project, lambda { |project|
          if project.present?
            project_id = project.is_a?(Project) ? project.id : project

            where("#{table_name}.is_for_all = ? " +
                      "OR EXISTS(SELECT custom_field_id FROM custom_fields_projects WHERE custom_field_id = #{table_name}.id AND project_id = ?)", true, project_id)
          else
            all
          end
        }
        scope :with_group, lambda { includes(:easy_group) }

        scope :visible, lambda { |*args|
          user = args.shift || User.current
          unless user.admin?
            visible_ids = visibility_condition_cache(user.id)
            sql         = "#{table_name}.visible = ? OR #{table_name}.type = ?"
            sql << " OR #{table_name}.id IN (#{visible_ids.join(',')})" unless visible_ids.empty?
            where(sql, true, 'TimeEntryCustomField')
          end
        }

        store :settings, coder: JSON

        acts_as_easy_translate

        safe_attributes 'easy_group_id', 'show_on_more_form', 'is_primary', 'show_empty', 'show_on_list', 'internal_name', 'easy_external_id',
                        'easy_min_value', 'easy_max_value', 'mail_notification', 'settings', 'unique', 'amount_type', 'reorder_to_position', 'clear_when_anonymize'
        safe_attributes 'disabled', :if => lambda { |cf, user| cf.non_deletable }

        after_destroy :clean_journal_details
        after_create :invalidate_cache

        alias_method_chain :possible_values, :easy_extensions
        alias_method_chain :value_class, :easy_extensions
        alias_method_chain :validate_custom_value, :easy_extensions
        alias_method_chain :group_statement, :easy_extensions
        alias_method_chain :visibility_by_project_condition, :easy_extensions
        alias_method_chain :visible_by?, :easy_extensions

        class << self
          alias_method_chain :for_all, :easy_extensions

          def disabled_sti_class
            EasyDisabledCustomField
          end

          def visibility_condition_cache(user_id)
            RequestStore.store["cf_visibility_cache_#{user_id}"] ||=
                connection.select_values("SELECT DISTINCT cfr.custom_field_id FROM #{Member.table_name} m" +
                                             " INNER JOIN #{MemberRole.table_name} mr ON mr.member_id = m.id" +
                                             " INNER JOIN custom_fields_roles cfr ON cfr.role_id = mr.role_id" +
                                             " WHERE m.user_id = #{user_id}")
          end

          def visibility_by_project_condition_cache(user_id, custom_field_id)
            key                     = "cf_visibility_project_cache_#{user_id}"
            RequestStore.store[key] ||= connection.select_rows("SELECT m.project_id, cfr.custom_field_id FROM #{Member.table_name} m" +
                                                                   " INNER JOIN #{MemberRole.table_name} mr ON mr.member_id = m.id" +
                                                                   " INNER JOIN custom_fields_roles cfr ON cfr.role_id = mr.role_id" +
                                                                   " WHERE m.user_id = #{user_id}")
            result                  = []
            RequestStore.store[key].each do |project_id_cf_id|
              result << project_id_cf_id[0].to_i if project_id_cf_id[1].to_i == custom_field_id
            end
            result
          end
        end

        def form_fields
          case self.class.name.to_sym
          when :IssueCustomField
            [:is_required, :is_for_all, :is_filter, :searchable, :show_on_more_form, :mail_notification]
          when :UserCustomField
            [:is_required, :is_filter, :editable]
          when :ProjectCustomField
            [:is_for_all, :is_filter, :show_on_list, :searchable, :is_required]
          when :DocumentCustomField
            [:is_required, :is_filter, :searchable]
          when :TimeEntryCustomField
            [:is_required, :is_filter]
          when :VersionCustomField
            [:is_required, :is_filter, :searchable]
          when :EasyProjectTemplateCustomField
            [:is_filter, :searchable]
          else
            [:is_required]
          end
        end

        def available_form_fields
          @available_form_fields = form_fields
          @available_form_fields.delete(:searchable) unless self.format.searchable_supported
          @available_form_fields
        end

        def available_form_fields_options
          if @available_form_fields_options.nil?
            @available_form_fields_options              = Hash.new { |hash, key| hash[key] = Hash.new }
            @available_form_fields_options[:is_for_all] = { :data => { :disables => '#custom_field_project_ids input' } }
          end
          @available_form_fields_options
        end

        def translated_name
          self.name
        end

        def date?
          format.date?(self)
        end

        def date_time?
          format.date_time?(self)
        end

        def summable?
          self.format.summable_supported
        end

        def summable_sql
          self.format.summable_sql(self)
        end

        def visible_on?(entity, user = User.current)
          case entity
          when Issue
            visible_by?(entity.project, user)
          else
            visible_by?(nil, user)
          end
        end

        def easy_groupable?
          false
        end

        def star_no
          return nil if field_format != 'easy_rating'
          if settings.is_a?(Hash) && (no = settings['star_no'].to_i) && no > 1 && no < 11
            settings['star_no'].to_i
          else
            5
          end
        end

        def precisions
          (0..3).map(&:to_s)
        end

        def precision
          self.settings['precision'].to_i
        end

        def strip_insignificant_zeros
          self.settings['strip_insignificant_zeros'] == '1'
        end

        def easy_group_id=(group_id_or_name)
          if group_id_or_name.blank?
            write_attribute(:easy_group_id, nil)
          elsif !EasyCustomFieldGroup.exists?(group_id_or_name)
            new_group = EasyCustomFieldGroup.create(name: ERB::Util.h(group_id_or_name))
            write_attribute(:easy_group_id, new_group.id)
          else
            write_attribute(:easy_group_id, group_id_or_name)
          end
        end

        def autocomplete_supported?
          self.format.autocomplete_supported
        end

        private

        def clean_journal_details
          JournalDetail.where(:property => 'cf', :prop_key => self.id.to_s).delete_all
        end

        def invalidate_cache
          RequestStore.store["#{self.class.name}_for_all"] = nil
        end

        def build_position_scope
          condition_hash = self.class.positioned_options[:scope].inject({}) do |h, column|
            h[column] = yield(column)
            h
          end
          self.class.unscoped.where(condition_hash)
        end

      end
    end

    module InstanceMethods

      def value_class_with_easy_extensions
        self.format.target_class_from_custom_field(self) if self.format.respond_to?(:target_class_from_custom_field)
      end

      def visible_by_with_easy_extensions?(project, user = User.current)
        visible_by_without_easy_extensions?(project, user) || self.is_a?(TimeEntryCustomField)
      end

      def possible_values_with_easy_extensions
        if self.field_format == 'country_select'
          ISO3166::Country.all_names_with_codes(::I18n.locale.to_s)
        else
          possible_values_without_easy_extensions
        end
      end

      def validate_custom_value_with_easy_extensions(custom_value)
        if self.field_format == 'autoincrement' && custom_value.value.blank?
          custom_value.value = CustomValue.get_next_autoincrement(self, custom_value.customized).to_s
        end
        validate_custom_value_without_easy_extensions(custom_value)
      end

      def group_statement_with_easy_extensions
        return format.group_statement(self) if multiple?
        group_statement_without_easy_extensions
      end

      def visibility_by_project_condition_with_easy_extensions(project_key = nil, user = User.current, id_column = nil)
        if visible? || user.admin? || (!user.anonymous? && project_key.nil? && self.class.customized_class && !self.class.customized_class.column_names.include?('project_id'))
          '1=1'
        elsif user.anonymous?
          '1=0'
        else
          project_key ||= "#{self.class.customized_class.table_name}.project_id"
          project_ids = self.class.visibility_by_project_condition_cache(user.id, self.id)
          if project_ids.empty?
            '1=0'
          else
            "#{project_key} IN (#{project_ids.join(',')})"
          end
        end
      end

    end

    module ClassMethods

      def for_all_with_easy_extensions
        RequestStore.store["#{self.name}_for_all"] ||= for_all_without_easy_extensions
      end

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'CustomField', 'EasyPatch::CustomFieldPatch', :before => EasyExtensions::REDMINE_CUSTOM_FIELDS
