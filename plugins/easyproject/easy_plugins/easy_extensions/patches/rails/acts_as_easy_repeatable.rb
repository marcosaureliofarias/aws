module EasyPatch
  module Acts
    module Repeatable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        #expects an colums
        # => easy_is_repeating:boolean, easy_next_start:date, easy_repeat_settings:text :limit => 4294967295
        # t.text :easy_repeat_settings, :limit => 4294967295, :default => nil # LIMIT MYSQL ONLY _!!!!!!!_
        # t.boolean :easy_is_repeating
        # t.date :easy_next_start
        # => options: Hash
        # => - :default_values -> will be set to the repeated entity
        def acts_as_easy_repeatable(options = {})
          cattr_accessor :easy_repeat_options
          self.easy_repeat_options                             = options.dup
          self.easy_repeat_options[:start_col]                 ||= :start_date
          self.easy_repeat_options[:end_col]                   ||= :due_date
          self.easy_repeat_options[:delayed_create_supported?] = true unless self.easy_repeat_options.has_key?(:delayed_create_supported?)

          define_method(:easy_repeating_start_date) do
            if self.respond_to?(self.easy_repeat_options[:start_col])
              if s = self.send(self.easy_repeat_options[:start_col])
                s = s.localtime if s.respond_to?(:localtime)
                begin
                  s.to_date rescue nil
                end
              end
            end
          end
          define_method(:easy_repeating_end_date) do
            if self.respond_to?(self.easy_repeat_options[:end_col])
              if s = self.send(self.easy_repeat_options[:end_col])
                s = s.localtime if s.respond_to?(:localtime)
                begin
                  s.to_date rescue nil
                end
              end
            end
          end
          if self.easy_repeat_options[:repeat_parent_id_col]
            define_method(:easy_repeating_parent_id) do
              if self.respond_to?(self.easy_repeat_options[:repeat_parent_id_col])
                self.send(self.easy_repeat_options[:repeat_parent_id_col])
              end
            end
            self.send(:belongs_to, :easy_repeat_parent, { :class_name => self.name, :foreign_key => self.easy_repeat_options[:repeat_parent_id_col] })
            self.send(:has_many, :easy_repeat_children, { :class_name => self.name, :foreign_key => self.easy_repeat_options[:repeat_parent_id_col] })
          end

          define_callbacks :easy_repeat

          attr_reader :easy_repeat_simple_repeat_end_at

          scope :easy_repeating, lambda { where(:easy_is_repeating => true) }
          scope :easy_to_repeat, lambda {
            t = self.arel_table;
            easy_repeating.where(t[:easy_next_start].lteq(Date.today).or(t[:easy_next_start].eq(nil)))
          }


          if self.respond_to?(:safe_attributes)
            safe_attributes 'easy_is_repeating'
            safe_attributes 'easy_repeat_settings'
            safe_attributes 'easy_next_start'
            safe_attributes 'easy_repeat_simple_repeat_end_at'
          end

          serialize :easy_repeat_settings, EasyExtensions::UltimateHashSerializer

          validates_with EasyExtensions::Validators::EasyRepeatingIssueValidator, :if => :easy_is_repeating?

          before_save :set_default_repeat_options, :if => :easy_is_repeating?
          after_save :save_entity_attributes, :if => Proc.new { |entity| entity.is_a?(Issue) && entity.update_repeat_entity_attributes }
          after_save :create_repeated, :if => :easy_is_repeating?

          send :include, EasyPatch::Acts::Repeatable::InstanceMethods
        end

        def migrate_repeating_columns(order = :up, options = {})
          columns        = { :easy_is_repeating => :boolean, :easy_repeat_settings => :text, :easy_next_start => :date }
          column_options = {
              :easy_repeat_settings => { :limit => 999.megabyte, :default => nil }
          }
          case order
          when :up
            columns.each do |column, type|
              self.connection.add_column (options[:table] || self.table_name), column, type, column_options[column] || {}
            end
          when :down
            columns.each do |column, type|
              self.connection.remove_column (options[:table] || self.table_name), column
            end
          else
            raise 'Repeating columns was not migrate, bad order given'
          end
        end

      end

      module InstanceMethods

        def self.included(base)
          base.extend ClassMethods
          base.const_set('CREATE_ALL_RECORDS_LIMIT', 31)
        end

        def set_default_repeat_options
          if self.easy_is_repeating_changed? || self.easy_repeat_settings['start_timepoint'].blank?
            self.easy_repeat_settings['start_timepoint'] = easy_repeating_start_date || Date.today
          end

          changing_repeat_options = easy_next_start_changed? || easy_repeat_settings_changed?
          if self.easy_next_start && changing_repeat_options
            self.easy_next_start -= 1.day unless self.easy_repeat_settings['period'] == 'daily'
            self.easy_next_start = count_next_start(self.easy_next_start, true)
          end

          self.easy_next_start ||= count_next_start(easy_repeating_start_date, true)
        end

        def create_repeated
          options = self.easy_repeat_settings

          if options['create_now'] == 'none'
            return true
          elsif options['create_now'] == 'count'
            count = options['create_now_count'].to_i
          elsif options['create_now'] == 'all'
            count = self.class::CREATE_ALL_RECORDS_LIMIT
          else
            return true
          end

          options.delete('create_now') #otherwise it will cycle, cuz repeat saves this record

          (0...count).each do |i|
            repeat if should_repeat?(self.easy_next_start || Date.today)
          end
        end

        def repeat(repeat_date = nil)
          repeat_date ||= self.easy_next_start if self.easy_next_start
          repeat_date ||= Date.today

          start_timepoint = self.easy_repeat_settings['start_timepoint']
          start_timepoint ||= self.easy_next_start if self.easy_next_start
          start_timepoint ||= repeat_date
          time_vector     = repeat_date - start_timepoint
          #issue has its own copy function and needs to move due date and start_date
          if is_a?(Issue)
            attributes_to_copy = (self.easy_repeat_settings['entity_attributes'] || {}).merge({ :easy_is_repeating => false, :easy_repeat_settings => nil, :easy_next_start => nil })
            repeated           = self.copy(attributes_to_copy, { :attachments => false, :subtasks => true, :copy_author => true })

            if repeated.start_date
              repeated.due_date   = repeat_date + (repeated.due_date - repeated.start_date) if repeated.due_date
              repeated.start_date = repeat_date
            else
              # in case due date is a required field
              repeated.due_date = repeat_date if repeated.due_date
            end
            repeated.parent_issue_id = parent_issue_id
          else
            repeated = self.dup
            if self.respond_to?(:custom_field_values)
              repeated.custom_field_values = self.custom_field_values.inject({}) { |mem, var| mem[var.custom_field_id.to_s] = var.value_for_params; mem }
            end
          end

          repeated.easy_is_repeating    = false
          repeated.easy_repeat_settings = nil
          repeated.easy_next_start      = nil
          if self.class.easy_repeat_options[:default_values].is_a?(Hash)
            self.class.easy_repeat_options[:default_values].each do |column, value|
              value = value.call if value.is_a?(Proc)
              repeated.send("#{column}=", value)
            end
          end

          self.easy_repeat_settings['start_timepoint'] = start_timepoint
          repeated.easy_repeate_update_time_cols(time_vector.days, start_timepoint) if repeated.respond_to?(:easy_repeate_update_time_cols)
          repeated.easy_repeat_parent = self if repeated.respond_to?(:easy_repeat_parent)

          if self.class.easy_repeat_options[:before_save].is_a?(Proc)
            self.class.easy_repeat_options[:before_save].call(repeated, self)
          end
          repeat_success = repeated.save(:validate => false)
          Rails.logger.error("REPEAT ERROR: Can not repeat #{repeated.class.name}##{repeated.id} because: #{repeated.errors.full_messages.join(', ')}") unless repeat_success

          if repeat_success || repeated.persisted?
            if self.class.easy_repeat_options[:after_save].is_a?(Proc)
              self.class.easy_repeat_options[:after_save].call(repeated, self)
            end

            self.easy_repeat_settings['repeated'] = self.easy_repeat_settings['repeated'].to_i + 1
            self.update_column(:easy_next_start, count_next_start(repeat_date))
          end

          self.update_column(:easy_repeat_settings, self.read_attribute(:easy_repeat_settings))
          self.reload

          repeat_success
        end

        def should_repeat?(date = Date.today)
          options = self.easy_repeat_settings

          case options['endtype']
          when 'endless'
            true
          when 'project_end'
            if (project = self.try(:project)) && project.easy_due_date
              project.easy_due_date >= date
            else
              true
            end
          when 'count'
            options['repeated'].to_i < options['endtype_count_x'].to_i
          when 'date'
            end_date = begin
              ; options['end_date'].to_date;
            rescue;
              nil
            end
            return false unless end_date
            end_date >= date
          else
            # it wouldn't repeat if someone forgot fill end count repeats
            false
          end
        end

        # => first_start - start asap
        def count_next_start(last_start, first_start = false)
          last_start ||= Date.today
          options    = self.easy_repeat_settings

          case options['period']
          when 'daily'
            last_start.increase_date(options["daily_#{options['daily_option']}_x"].to_i, options['daily_option'] == 'work')
          when 'weekly'
            options['week_days'] = [options['week_days']] unless options['week_days'].is_a?(Array)
            last_start.closest_week_day(options['week_days'].map(&:to_i))
          when 'monthly'
            next_month = last_start.months_since(options['monthly_period'].to_i).beginning_of_month unless first_start
            if options['monthly_option'] == 'xth'
              next_month ||= (last_start.mday <= options['monthly_day'].to_i) ? last_start : last_start.next_month.beginning_of_month
              return next_month + (options['monthly_day'].to_i - next_month.mday)
            end

            next_month                      ||= last_start.beginning_of_month

            options['monthly_custom_order'] = options['monthly_custom_order'].to_i + 1 if options['monthly_custom_order'].to_i < 0
            wday                            = (next_month - 1.day).next_week_day(options['monthly_custom_day'].to_i) + (options['monthly_custom_order'].to_i - 1) * 7

            while wday.month != next_month.month
              wday -= 7
            end
            wday
          when 'yearly'
            if options['yearly_option'] == 'date'
              if first_start
                year = last_start.year
                if last_start.month > options['yearly_month'].to_i || (last_start.month == options['yearly_month'].to_i && last_start.day > options['yearly_day'].to_i)
                  year += 1
                end
              else
                year = last_start.year + options['yearly_period'].to_i
              end

              return Date.new(year, options['yearly_month'].to_i, options['yearly_day'].to_i)
            end

            if first_start
              year = last_start.year
              year += 1 if last_start.month >= options['yearly_month'].to_i
            else
              year = last_start.year + options['yearly_period'].to_i
            end

            month_begin                    = Date.new(year, options['yearly_custom_month'].to_i, 1)
            options['yearly_custom_order'] = options['yearly_custom_order'].to_i + 1 if options['yearly_custom_order'].to_i < 0
            wday                           = month_begin.next_week_day(options['yearly_custom_day'].to_i) + (options['yearly_custom_order'].to_i - 1) * 7

            # douprava, pokud bych prekrocil na dalsi mesic
            while wday.month != month_begin.month
              wday -= 7
            end

            wday
          end
        end

        def easy_repeat_settings=(settings)
          if !settings.blank? && self.easy_repeat_settings.is_a?(Hash)
            settings['start_timepoint'] ||= self.easy_repeat_settings['start_timepoint']
            settings['repeated']        ||= self.easy_repeat_settings['repeated']
            if settings['repeat_hour'] && settings['repeat_hour'].match(/^(\d\d):(\d\d)$/)
              settings['repeat_hour'] = $1
            end
          end

          if settings && settings['simple_period'].present? && settings['period'].nil?
            case settings['simple_period'].to_sym
            when :daily
              settings['daily_option'] ||= 'each'
              settings['daily_each_x'] ||= '1'
              settings['period']       = 'daily'
            when :weekly
              start_day             = easy_repeating_start_date.try(:wday)
              settings['week_days'] ||= [start_day ? start_day.to_s : '0']
              settings['period']    = 'weekly'
            when :monthly, :quart_year, :half_year
              settings['monthly_option'] ||= 'xth'
              settings['monthly_day']    ||= '1'
              settings['period']         = 'monthly'
              case settings['simple_period'].to_sym
              when :monthly
                settings['monthly_period'] = 1
              when :quart_year
                settings['monthly_period'] = 3
              when :half_year
                settings['monthly_period'] = 6
              end
            when :yearly
              d = easy_repeating_start_date || Date.today
              settings['monthly_option'] ||= 'xth'
              settings['yearly_option']  ||= 'date'
              settings['yearly_period']  ||= 1
              settings['yearly_month']   ||= d.month
              settings['yearly_day']     ||= d.day
              settings['period']         = 'yearly'
            end

            if settings['end_date'].present?
              settings['endtype'] = 'date'
            end
            if settings['endtype_count_x'] && settings['endtype_count_x'].to_i > 0
              settings['endtype'] = 'count'
            end

            settings['create_now'] ||= delayed_create_supported? ? 'none' : 'all'
            settings['endtype']    ||= 'endless'

            self.easy_is_repeating = true
            settings.delete('simple_period')
          end

          settings = (self.easy_repeat_settings || {}).merge(settings || {})
          write_attribute(:easy_repeat_settings, settings)
        end

        def available_simple_repeatings
          [
              :daily,
              :weekly,
              :monthly,
              :yearly,
              # ------
              :custom
          ]
        end

        def easy_repeat_simple_repeat_end_at=(value)
          @easy_repeat_simple_repeat_end_at = value
        end

        def save_entity_attributes
          return unless self.easy_is_repeating || (self.parent && self.parent.easy_is_repeating)
          repeat_settings = self.easy_repeat_settings.dup.merge({ 'entity_attributes' => self.attributes.except('easy_repeat_settings', 'id', 'root_id', 'parent_id', 'lft', 'rgt', 'created_on', 'updated_on') })
          self.update_column(:easy_repeat_settings, repeat_settings)
        end

        def delayed_create_supported?
          self.class.easy_repeat_options[:delayed_create_supported?]
        end

        module ClassMethods
        end
      end

    end
  end
end
