module EasyPatch
  module UserPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        has_many :time_entries
        has_many :easy_favorites
        has_many :favorite_projects, lambda { distinct }, :through => :easy_favorites, :source => :entity, :source_type => 'Project', :dependent => :destroy
        has_many :favorite_issues, lambda { distinct }, :through => :easy_favorites, :source => :entity, :source_type => 'Issue', :dependent => :destroy

        has_many :easy_attendances, :dependent => :destroy
        has_many :easy_page_tabs, :class_name => 'EasyPageUserTab', :foreign_key => 'user_id', :dependent => :destroy
        has_many :assigned_issues, :class_name => 'Issue', :foreign_key => 'assigned_to_id'

        has_many :easy_issue_timers, :dependent => :destroy
        has_many :easy_attendance_user_arrival_notifies, :dependent => :destroy

        has_many :easy_sliding_panels_locations, :dependent => :destroy

        has_many :easy_attendance_activity_user_limits, :dependent => :destroy

        has_many :old_passwords, dependent: :delete_all

        has_many :easy_oauth_authentications, dependent: :delete_all
        has_many :easy_oauth_access_grants, dependent: :delete_all

        has_one :working_time_calendar, :class_name => 'EasyUserWorkingTimeCalendar', :foreign_key => 'user_id', :dependent => :destroy
        has_one :easy_avatar, :class_name => 'EasyAvatar', :as => :entity, :dependent => :destroy
        belongs_to :easy_user_type

        before_create :set_attributes_from_auth_source_before_save
        before_create :set_default_easy_user_type, :unless => :easy_user_type
        after_create :create_my_page_from_page_template
        after_create :create_easy_user_working_time_calendar_from_default, :if => Proc.new { |u| !Rails.env.test? && u.working_time_calendar.nil? }
        after_create :set_working_time_limits
        after_create :create_user_tokens
        after_create :set_attributes_from_auth_source_after_save
        after_create :assign_to_group
        after_save :create_journal
        before_save :save_old_password, if: -> { hashed_password_changed? && OldPassword.table_exists? }

        before_save :update_easy_digest_token
        before_save { self.easy_avatar_url = easy_avatar_url_was if easy_avatar_url && easy_avatar_url.length > 255 } # hotfix sso_login bug when avatar url is too long?

        after_commit :apply_page_template_by_user_type, :if => Proc.new { |u| u.apply_default_page_template }

        after_touch :clear_association_cache

        acts_as_attachable
        acts_as_taggable_on :tags, { :easy_query_class => 'EasyUserQuery', :referenced_collection_name => 'users', :heading_label => 'label_user_plural' }
        acts_as_easy_journalized non_journalized_columns:          ['hashed_password', 'easy_digest_token', 'salt'],
                                 format_detail_boolean_columns:    ['admin', 'easy_system_flag', 'easy_lesser_admin'],
                                 format_detail_reflection_columns: ['easy_user_type_id']

        enum easy_online_status: { offline: 0, online: 1, away: 2, dnd: 3, invisible: 4 }, _prefix: :easy_online_status

        remove_validation :login, 'validates_format_of'
        validates_format_of :login, :with => /\A[a-z0-9_\-@\.\+]*\z/i
        remove_validation :login, 'validates_length_of'
        validates_length_of :login, :maximum => 255
        validates_length_of :easy_mail_signature, :maximum => 65535, :allow_nil => true

        validate :validate_password_uniqueness, if: -> { OldPassword.table_exists? && password_match_with_last_used }

        validate :validate_tokens
        validate :validate_easy_license, :on => :create

        attr_reader :rss_key_error, :api_key_error, :apply_default_page_template
        attr_accessor :in_mobile_view, :in_iframe, :selected_role_id

        serialize :easy_lesser_admin_permissions, Array

        safe_attributes 'easy_mail_signature', 'tag_list'
        safe_attributes 'sso_provider', 'sso_uuid', 'easy_avatar_url'

        safe_attributes 'admin', 'easy_lesser_admin', 'easy_lesser_admin_permissions',
                        :if => lambda { |user, current_user| current_user.admin? }

        safe_attributes 'self_registered', :if => lambda { |user, current_user| user.new_record? }

        safe_attributes 'status', :if => lambda { |user, current_user| current_user.easy_lesser_admin_for?(:users) && user.logged? }

        safe_attributes 'rss_key',
                        'api_key',
                        'auth_source_id',
                        'generate_password',
                        'must_change_passwd',
                        'login',
                        :if => lambda { |user, current_user| user.auth_change_allowed? }

        safe_attributes 'easy_system_flag',
                        'easy_user_type_id',
                        'apply_default_page_template',
                        'easy_external_id',
                        :if => lambda { |user, current_user| current_user.easy_lesser_admin_for?(:users) }

        safe_attributes 'group_ids',
                        :if => lambda { |user, current_user| current_user.easy_lesser_admin_for?(:groups) && current_user.easy_lesser_admin_for?(:users) && !user.new_record? }

        scope :easy_type_internal, lambda { joins(:easy_user_type).where("#{EasyUserType.table_name}.internal" => true) }
        scope :easy_type_external, lambda { joins(:easy_user_type).where("#{EasyUserType.table_name}.internal" => false) }
        scope :easy_type_partner, lambda { joins(:easy_user_type).where("#{EasyUserType.table_name}.partner" => true) }
        scope :easy_type_regular, lambda { joins(:easy_user_type).where("#{EasyUserType.table_name}.partner" => false) }
        scope :users_in_meeting_calendar, lambda { joins(:easy_user_type).where("#{EasyUserType.table_name}.show_in_meeting_calendar") }
        scope :with_easy_avatar, lambda { preload(Setting.gravatar_enabled? ? :email_addresses : :easy_avatar) }

        set_associated_query_class EasyUserQuery

        # DO NOT CHANGE THIS !!!
        # Based on this value is calculated easy_digest_token
        User.send(:const_set, 'DIGEST_AUTHENTICATION_REALM', 'Locked content'.freeze)

        alias_method_chain :reload, :easy_extensions
        alias_method_chain :allowed_to?, :easy_extensions
        alias_method_chain :visible?, :easy_extensions
        alias_method_chain :cache_key, :easy_extensions
        alias_method_chain :notify_about?, :easy_extensions
        alias_method_chain :membership, :easy_extensions #performance tweak - check www.redmine.org/issues/23519
        alias_method_chain :remove_references_before_destroy, :easy_extensions

        class << self

          alias_method_chain :valid_notification_options, :easy_extensions
          alias_method_chain :try_to_login, :easy_extensions
          alias_method_chain :verify_session_token, :easy_extensions

          def additional_select_options
            User.current.logged? ? { "<< #{l(:label_me)} >>" => 'me' } : {}
          end

          def easy_oauth_authenticate(provider, email, uuid, signed_in_resource = nil, username: nil)
            if auth = EasyOauthAuthentication.find_by(provider: provider.to_s, uuid: uuid.to_s)
              User.find(auth.user_id)
            elsif user = User.find_by(email: email)
              # User record exists, but don't have any information for this provider
              auth          = EasyOauthAuthentication.new
              auth.user_id  = user.id
              auth.provider = provider
              auth.uuid     = uuid
              auth.save!

              user
            else
              # New user
              user          = User.new
              user.email    = email
              user.password = Devise.friendly_token[0, 20]
              user.username = username
              user.skip_confirmation!
              user.save!

              auth          = EasyOauthAuthentication.new
              auth.user_id  = user.id
              auth.provider = provider
              auth.uuid     = uuid
              auth.save!

              user
            end
          end

        end

        def roles_for_all_projects
          @roles_for_all_projects ||= Role.joins(:members).where("#{Member.table_name}.user_id = ?", self.id).distinct.to_a
        end

        def roles
          return @roles if @roles
          base = Role.joins(members: :project).where(["#{Project.table_name}.status <> ?", Project::STATUS_ARCHIVED]).where(projects: { easy_is_easy_template: false }).where(members: { user_id: id })
          if Redmine::Database.mysql?
            base = base.group("#{Role.table_name}.id")
          else
            base = base.distinct
          end
          @roles = base
        end

        def role_ids
          @role_ids ||= roles.pluck(:id)
        end

        def all_roles
          @all_roles ||= (roles.to_a + [(self.logged? ? Role.non_member : Role.anonymous)])
        end

        def <=>(user)
          self.name <=> user.name
        end

        def project
          nil
        end

        def rss_key=(key)
          if key == ''
            @rss_key_error = false
          else
            @rss_key_error = self.rss_token.update_attributes(:value => key)
          end
        end

        def api_key=(key)
          if key == ''
            @api_key_error = false
          else
            @api_key_error = self.api_token.update_attributes(:value => key)
          end
        end

        def validate_tokens
          errors.add(:rss_key, :invalid) if @rss_key_error == false
          errors.add(:api_key, :invalid) if @api_key_error == false
        end

        def allowed_to_globally_view_all_time_entries?(context = nil)
          allowed_to?(:view_time_entries, context, :global => true) do |role, user|
            role.time_entries_visibility == 'all'
          end
        end

        def user_time_entry_setting
          self.pref.user_time_entry_setting.nil? ? :hours : self.pref.user_time_entry_setting.to_sym
        end

        def user_time_entry_setting_hours?
          (self.user_time_entry_setting == :hours) || (self.user_time_entry_setting == :all)
        end

        def user_time_entry_setting_range?
          (self.user_time_entry_setting == :range) || (self.user_time_entry_setting == :all)
        end

        def sum_spent_time_for(date)
          return 0.0 if new_record?

          TimeEntry.where(:user_id => id, :spent_on => date).sum(:hours)
        end

        def spent_time_percentage_for(date)
          st = sum_spent_time_for(date)
          wh = working_hours(date)

          if wh > 0
            st / wh * 100
          else
            0.0
          end
        end

        def get_user_attendance_year_sum(activity, options = {})
          year = options[:query].try(:period_start_date).try(:year) || Date.today.year
          activity.sum_in_days_easy_attendance(self, year)
        end

        def attribute_css_classes(attribute_name, val)
          case attribute_name
          when :attendance_in_period_diff_working_time_percent, :time_entry_in_period_diff_working_time_percent, :working_attendance_percent
            if val > 0.8
              ' scheme-3'
            elsif val > 0.5
              ''
            else
              ' scheme-1'
            end
          else
            ''
          end
        end

        def current_working_time_calendar
          @current_working_time_calendar ||= (self.working_time_calendar || create_easy_user_working_time_calendar_from_default)
        end

        def default_working_hours
          self.current_working_time_calendar.try(:default_working_hours) || 8.0
        end

        def cumulative_work_time_this_year(start_date, end_date, options = {})
          return 0.to_d unless current_working_time_calendar
          @exception_cache_hit ||= current_working_time_calendar.exception_between(options[:query].period_start_date, options[:query].period_end_date) if options[:query]
          current_working_time_calendar.sum_working_hours(start_date.beginning_of_year, end_date)
        end

        def periodic_work_time(start_date, end_date, options = {})
          return 0.to_d unless current_working_time_calendar
          @exception_cache_hit ||= current_working_time_calendar.exception_between(options[:query].period_start_date, options[:query].period_end_date) if options[:query]
          current_working_time_calendar.sum_working_hours(start_date, end_date)
        end

        def get_user_attendance_limit(easy_attendance_activity_id)
          easy_attendance_activity_user_limits.find_by_easy_attendance_activity_id(easy_attendance_activity_id).try(:days).to_f
        end

        def get_user_attendance_accumulated(easy_attendance_activity_id)
          easy_attendance_activity_user_limits.find_by_easy_attendance_activity_id(easy_attendance_activity_id).try(:accumulated_days).to_f
        end

        def get_user_attendance_remaining(activity, options = {})
          year = options[:query].try(:period_start_date).try(:year) || Date.today.year
          activity.user_vacation_remaining_in_days(self, year)
        end

        def working_hours(date = nil)
          return 8.0 unless date.is_a?(Date)
          return working_hours_between(date, date)[date] || 8.0

          # non_working_attendance = self.easy_attendances.non_working.between(date, date).sum_spent_time(self.current_working_time_calendar, true)
          # non_working_attendance ||= 0.0
          #
          # wc_hours = self.current_working_time_calendar.working_hours(date) if self.current_working_time_calendar
          # wc_hours ||= 8.0
          #
          # if wc_hours > 0.0 && non_working_attendance > 0.0
          #   if wc_hours > non_working_attendance
          #     wc_hours - non_working_attendance
          #   else
          #     0.0
          #   end
          # else
          #   wc_hours
          # end
        end

        def working_hours_between(day_from = nil, day_to = nil)
          day_from ||= Date.today
          day_to   ||= Date.today

          Rails.cache.fetch("working_hours_between/#{day_from}_#{day_to}/#{self.cache_key}", :expires_in => 1.day) do
            get_working_hours_between(day_from, day_to)
          end
        end

        def get_working_hours_between(day_from, day_to)
          default_working_hours = self.current_working_time_calendar.default_working_hours if self.current_working_time_calendar
          default_working_hours ||= 8.0
          half_working_hours    = default_working_hours / 2

          h                      = {}
          non_working_attendance = self.easy_attendances.non_working.between(day_from, day_to).get_spent_time(default_working_hours, half_working_hours, true)
          if non_working_attendance
            non_working_attendance.each do |day, hours|
              if hours == 0.0
                h[day] ||= default_working_hours
              elsif hours <= half_working_hours
                h[day] ||= half_working_hours
              else
                h[day] ||= 0.0
              end
            end
          end

          wc_hours = self.current_working_time_calendar.working_hours_between(day_from, day_to) if self.current_working_time_calendar
          if wc_hours
            wc_hours.each do |day, hours|
              h[day] ||= hours
            end
          end

          day_from.upto(day_to) do |day|
            h[day] ||= 0.0
          end

          h
        end

        def available_working_hours(date = nil)
          working_hours(date)
        end

        def available_working_hours_between(day_from = nil, day_to = nil)
          working_hours_between(day_from, day_to)
        end

        def limit_assignable_users_for_project?(project)
          if project.nil? || User.current.admin?
            false
          else
            roles = roles_for_project(project)
            if roles.empty?
              false
            else
              roles.all?(&:limit_assignable_users)
            end
          end
        end

        def easy_project_ids_by_role(options = {})
          @easy_project_ids_by_role ||= Project.unscoped do
            group    = anonymous? ? Group.anonymous : Group.non_member
            group_id = group&.id

            members = Member.joins(:project, :member_roles)
            members = members.where("#{Project.table_name}.status <> ?", Project::STATUS_ARCHIVED) unless options[:include_archived]
            members = members.where("#{Member.table_name}.user_id = ? OR (#{Project.table_name}.is_public = ? AND #{Member.table_name}.user_id = ?)", self.id, true, group_id).
                pluck(:user_id, :role_id, :project_id)

            hash = {}
            members.each do |user_id, role_id, project_id|
              next if user_id != id && project_ids.include?(project_id)
              hash[role_id] ||= []
              hash[role_id] << project_id
            end

            result = Hash.new([])
            if hash.present?
              roles = Role.where(:id => hash.keys).to_a
              hash.each do |role_id, proj_ids|
                role = roles.detect { |r| r.id == role_id }
                if role
                  result[role] = proj_ids.uniq
                end
              end
            end
            result
          end
        end

        def copy_roles_from(source_user)
          return if self.new_record? || !source_user.is_a?(User) || source_user.new_record?

          projects_and_roles = MemberRole.includes(:member).where(members: { user_id: source_user.id }, inherited_from: nil).group_by { |mr| mr.member.project_id }

          projects_and_roles.each do |member_project_id, member_roles|
            role_ids = member_roles.collect(&:role_id)
            if (membership = Member.find_by(user_id: self.id, project_id: member_project_id))
              (role_ids - membership.role_ids).each do |role_id|
                MemberRole.create(member_id: membership.id, role_id: role_id)
              end
            else
              Member.create(role_ids: role_ids, user_id: self.id, project_id: member_project_id)
            end
          end
        end

        def get_easy_attendance_last_arrival
          return self.easy_attendances.where("#{EasyAttendance.table_name}.departure IS NULL").last
        end

        def get_easy_attendance_last_departure
          return self.easy_attendances.where("#{EasyAttendance.table_name}.departure IS NOT NULL").last
        end

        def get_easy_attendance_yesterday_departure
          return self.easy_attendances.where(["(#{EasyAttendance.table_name}.departure BETWEEN ? AND ? )", DateTime.yesterday.beginning_of_day, DateTime.yesterday.end_of_day]).last
        end

        def editable_custom_fields
          visible_custom_field_values.map(&:custom_field).uniq
        end

        def empty_today_attendance?
          @empty_today_attendance ||= self.easy_attendances.where(["#{EasyAttendance.table_name}.arrival BETWEEN ? AND ?", self.user_time_in_zone.beginning_of_day, self.user_time_in_zone.end_of_day]).count == 0
        end

        def is_in_work?
          return @is_in_work unless @is_in_work.nil?
          if current_attendance
            @is_in_work = current_attendance.departure.nil?
          else
            @is_in_work = false
          end

          return @is_in_work
        end

        def anonymize!
          if self.anonymous?
            self.errors.add(:base, :error_anonymize_anonymous)
            return false
          end
          self.custom_values.where(custom_field_id: anonymized_custom_fields).delete_all
          self.lastname        = l(:field_user)
          self.firstname       = l(:field_anonymized)
          self.email_addresses = []
          self.mail            = Redmine::Utils.random_hex(8) + '@' + Setting.host_name || 'example.com'
          self.save(validate: false)
        end

        def anonymized_custom_fields
          UserCustomField.where(clear_when_anonymize: true)
        end

        def last_today_attendance
          @last_today_attendance ||= self.easy_attendances.joins(:easy_attendance_activity).where(:easy_attendances => { :arrival => Time.now.beginning_of_day..Time.now.end_of_day }).order(:arrival).last
          @last_today_attendance
        end

        def current_attendance
          return @current_attendance if @current_attendance || @current_attendance_added
          rounded_time        = EasyAttendance.round_time(Time.now)
          tbl                 = EasyAttendance.table_name
          @current_attendance = self.easy_attendances.reportable.preload(:easy_attendance_activity).where(:easy_attendances => { :arrival => Time.now.beginning_of_day..rounded_time }).where(["(#{tbl}.arrival <= :current_time AND #{tbl}.departure >= :current_time AND #{tbl}.departure <= :end_day) OR (#{tbl}.arrival <= :current_time AND #{tbl}.departure IS NULL) ", { :current_time => rounded_time, :end_day => EasyAttendance.round_time(Time.now.end_of_day) }]).order("#{tbl}.arrival DESC").first
          @current_attendance
        end

        def last_today_attendance_to_now
          return @last_today_non_work_attendance_to_now if @last_today_non_work_attendance_to_now || @last_today_non_work_attendance_to_now_added

          @last_today_non_work_attendance_to_now ||= self.easy_attendances.preload(:easy_attendance_activity)
                                                         .where({ :arrival => Time.now.beginning_of_day..EasyAttendance.round_time(Time.now) })
                                                         .order(:arrival)
                                                         .last
        end

        def is_work_time?(time)
          cwtc = self.current_working_time_calendar
          # calendar is not set
          return true if cwtc.nil?

          work_time = cwtc.try(:time_to)
          # working time is not set
          return true if !work_time
          # not working day
          day = time.to_date rescue Date.today
          return false if !cwtc.working_day?(day)
          time.min + time.hour.minutes < work_time.min + work_time.hour.minutes
        end

        def in_mobile_view?
          return self.in_mobile_view
        end

        def user_time_in_zone(time = nil)
          if self.time_zone.nil?
            return time.to_time.localtime
          else
            return time.in_time_zone(self.time_zone)
          end
        rescue StandardError
          user_time_in_zone(Time.now)
        end

        def user_civil_time_in_zone(y = 0, m = 0, d = 0, h = 0, min = 0, sec = 0)
          zone = self.time_zone ? Time.use_zone(self.time_zone) { Time.zone } : Time
          zone.local(y, m, d, h, min, sec)
        rescue ArgumentError
        end

        def convert_time_to_user_civil_time_in_zone(time)
          user_civil_time_in_zone(time.year, time.month, time.day, time.hour, time.min, time.sec)
        rescue NoMethodError
        end

        def easy_lesser_admin_for?(area_name)
          if self.admin?
            true
          elsif area_name.blank? || !respond_to?(:easy_lesser_admin) || !self.easy_lesser_admin? || self.easy_lesser_admin_permissions.blank?
            false
          else
            !!self.easy_lesser_admin_permissions.detect { |p| p.to_s == area_name.to_s }
          end
        end

        def easy_user_type_for?(setting)
          user_type = self.easy_user_type
          return true if user_type.blank?

          user_type.easy_user_type_for?(setting)
        end

        def internal_client?
          self.admin? || self.easy_user_type.nil? || self.easy_user_type.internal?
        end

        def external_client?
          self.easy_user_type && !self.easy_user_type.internal?
        end

        def set_default_easy_user_type
          self.easy_user_type_id = EasyUserType.where(:is_default => true).pluck(:id).first
        end

        def visible_custom_field_values
          custom_field_values.select do |value|
            if value.custom_field.settings[:personal_visibility] == '1'
              User.current.id == value.customized.id || value.custom_field.visible_by?(nil, User.current)
            else
              value.custom_field.visible_by?(nil, User.current)
            end
          end
        end

        def visible_custom_field_values_primary
          visible_custom_field_values.reject { |c| (c.custom_field.is_primary? && c.value.blank?) || !c.custom_field.is_primary? }
        end

        def visible_custom_field_values_non_primary
          (self.visible_custom_field_values - self.visible_custom_field_values_primary).reject { |c| c.value.blank? }
        end

        def allowed_to_at_least_one_action?(actions, project)
          actions.each do |action|
            if self.allowed_to?(action, project)
              return true
            end
          end
          false
        end

        def groups_names
          self.groups.map(&:lastname).uniq.join(', ')
        end

        def mail_with_name
          %{"#{name}" <#{mail}>}
        end

        def notify_mails
          email_addresses.where(notify: true).pluck(:address)
        end

        def execute(&block)
          origin_user  = User.current
          User.current = self
          yield
        rescue
          raise
        ensure
          User.current = origin_user
        end

        def as_admin(&block)
          original           = User.current.admin
          User.current.admin = true
          yield
        rescue
          raise
        ensure
          User.current.admin = original
        end

        def easy_digest_token_expired?
          easy_digest_token.blank?
        end

        def preloaded_membership_by_project_id
          @preloaded_membership_by_project_id ||= {}
        end

        def preload_membership_for(project_ids)
          return if project_ids.empty?
          project_ids = project_ids.uniq
          result      = members.where(project_id: project_ids).preload(:roles).each_with_object({}) { |m, res| res[m.project_id] = m }
          project_ids.each_with_object(result) { |pid, res| res[pid] ||= nil }
          preloaded_membership_by_project_id.merge!(result)
        end

        def show_passwd_expiration_notification
          return false if User.current.pref.hide_notification_passwd_expiration

          period = Setting.password_max_age.to_i
          if period.zero?
            false
          else
            changed_on        = self.passwd_changed_on || Time.at(0)
            must_change_after = (changed_on - period.days.ago) / 1.day
            if must_change_after.between?(0, 7)
              must_change_after.to_i
            else
              false
            end
          end
        end

        def online?
          easy_online_status_online? || easy_online_status_dnd?
        end

        def set_online_status(status)
          update_columns(easy_online_status: status, easy_online_status_changed_at: Time.now)
        end

        def easy_online_status
          if attributes['easy_online_status'] == 'online' && easy_online_status_expired?
            'away'
          else
            attributes['easy_online_status']
          end
        end

        def easy_online_status_online?
          easy_online_status == 'online'
        end

        def easy_online_status_expired?
          (Time.now - easy_online_status_changed_at).to_i > EasySetting.value('easy_online_status_expiration_seconds').to_i
        end

        def auth_change_allowed?(current_user = User.current)
          self == current_user ||
            current_user.admin? ||
            (current_user.easy_lesser_admin_for?(:users) &&
              (!self.admin? && !self.easy_lesser_admin?) ||
              self.new_record?)
        end

        private

        def validate_password_uniqueness
          message = l(:error_password_unique, count: EasySetting.value('unique_password_counter').to_i)
          # Password uniqueness validation based on setting
          errors.add(:password, message)
        end

        def password_match_with_last_used
          self.old_passwords.last_used.each do |passwd|
            new_hashed = User.hash_password("#{passwd.salt}#{User.hash_password(self.password)}")
            return true if new_hashed == passwd.hashed_password
          end

          false
        end

        def save_old_password
          self.old_passwords.build(user: self, hashed_password: self.hashed_password, salt: self.salt)
        end

        def set_attributes_from_auth_source_before_save
          return true unless self.auth_source

          if self.auth_source.easy_options && self.auth_source.onthefly_register?
            self.easy_user_type_id ||= self.auth_source.easy_options['easy_user_type'] if self.auth_source.easy_options['easy_user_type']
            self.language          ||= self.auth_source.easy_options['language'] if self.auth_source.easy_options['language']
          end
        end

        def set_attributes_from_auth_source_after_save
          return true if self.auth_source_id.blank? || self.auth_source.nil?

          projects_and_roles = self.auth_source.easy_options['projects_and_roles'] || {}
          projects_and_roles.each do |project_id, role_ids|
            m = Member.new(:user_id => self.id, :project_id => project_id, :role_ids => role_ids)
            m.save
          end
        end

        def create_my_page_from_page_template
          if EasyPage.table_exists? && EasyPageTemplate.table_exists? && EasyPageZoneModule.table_exists? && EasyPage.find_by(page_name: 'my-page')
            my_page_template = nil

            if !self.auth_source.nil? && !self.auth_source.easy_options['default_my_page_template'].blank?
              my_page_template = EasyPageTemplate.find_by(id: self.auth_source.easy_options['default_my_page_template'])
            end

            my_page_template ||= EasyPageTemplate.default_template_for_page(EasyPage.find_by(page_name: 'my-page'))

            if my_page_template
              EasyPageZoneModule.create_from_page_template(my_page_template, self.id, nil)
            end
          end
        end

        def create_easy_user_working_time_calendar_from_default
          return if !EasyUserWorkingTimeCalendar.table_exists? || !self.working_time_calendar.nil?
          default_calendar = EasyUserWorkingTimeCalendar.where(:user_id => nil, :parent_id => nil).reorder([{ :is_default => :desc }, { :builtin => :desc }]).first
          if default_calendar
            self.working_time_calendar = default_calendar.assign_to_user(self, true)
          end
        end

        def create_user_tokens
          self.rss_key
          self.api_key
        end

        def validate_easy_license
          message = l(:'license_manager.user_limit', :email => EasyExtensions::EasyProjectSettings.app_email)
          errors.add(:base, message) if self.internal_client? && !EasyLicenseManager.has_license_limit?(:internal_user_limit)
          errors.add(:base, message) if self.external_client? && !EasyLicenseManager.has_license_limit?(:external_user_limit)
        end

        def update_easy_digest_token(clear_password = nil, update_now = false)
          clear_password ||= password

          if saved_change_to_login?
            self.easy_digest_token = nil
          end

          if clear_password
            self.easy_digest_token = Digest::MD5.hexdigest("#{login}:#{User::DIGEST_AUTHENTICATION_REALM}:#{clear_password}")
          end

          if !new_record? && update_now
            self.update_column(:easy_digest_token, easy_digest_token)
          end
        end

        def assign_to_group
          return if !self.self_registered?

          if (group_id = EasySetting.value('self_registered_user_to_group_id') && Group.where(id: group_id).exists?)
            self.group_ids += [group_id]
          end
        end

        def set_working_time_limits
          return true unless Redmine::Plugin.installed?(:easy_attendances)
          limits = Setting.plugin_easy_attendances[:easy_attendance_activity_user_limit]
          return true unless limits

          limits.each do |activity_id, days|
            next unless days.present?
            limit = self.easy_attendance_activity_user_limits.build(easy_attendance_activity_id: activity_id, days: days.to_f)
            limit.save(validate: false)
          end
        end

        def apply_page_template_by_user_type
          page_template = EasyPageTemplate.find_by(id: easy_user_type.try(:easy_page_template_id).to_i)
          EasyPageZoneModule.create_from_page_template(page_template, id) if page_template
        end

      end
    end

    module InstanceMethods

      def reload_with_easy_extensions(*args)
        @all_roles                     = nil
        @roles                         = nil
        @role_ids                      = nil
        @roles_for_all_projects        = nil
        @easy_project_ids_by_role      = nil
        @current_working_time_calendar = nil
        reload_without_easy_extensions(*args)
      end

      def cache_key_with_easy_extensions
        if new_record?
          'users/new'
        else
          "users/#{id}-#{updated_on.strftime('%Y%m%d%H%M%S')}"
        end
      end

      def allowed_to_with_easy_extensions?(action, context, options = {}, &block)
        options      ||= {}
        ignore_admin = options[:ignore_admin] || false
        if context && context.is_a?(Project)
          return false unless context.allows_to?(action)
          if context.easy_is_easy_template?
            return false if action == :log_time
            return self.allowed_to?(action, nil, options.merge({ :global => true }), &block)
          end
          # Admin users are authorized for anything else
          return true if admin? && !ignore_admin

          rfp = roles_for_project(context)
          return false unless rfp
          rfp.any? { |role|
            (context.is_public? || role.member?) &&
                role.allowed_to?(action) &&
                (block_given? ? yield(role, self) : true)
          }
        elsif context && context.is_a?(Array)
          if context.empty?
            false
          else
            # Authorize if user is authorized on every element of the array
            context.map { |project| allowed_to?(action, project, options, &block) }.reduce(:&)
          end
        elsif options[:global]
          # Admin users are always authorized
          return true if admin? && !ignore_admin

          # authorize if user has at least one role that has this permission
          all_roles.any? { |role|
            role.allowed_to?(action) &&
                (block_given? ? yield(role, self) : true)
          }
        else
          false
        end
      end

      def notify_about_with_easy_extensions?(object)
        n = notify_about_without_easy_extensions?(object)

        if n && object.is_a?(Issue) && self.pref.no_notified_if_issue_closing && object.closed? && !object.closing?
          n = false
        end

        n
      end

      def membership_with_easy_extensions(project)
        project_id = project.is_a?(Project) ? project.id : project

        @membership_by_project_id ||= Hash.new { |h, project_id|
          h[project_id] = preloaded_membership_by_project_id.key?(project_id) ? preloaded_membership_by_project_id[project_id] : members.where(:project_id => project_id).first
        }
        @membership_by_project_id[project_id]
      end

      def visible_with_easy_extensions?(user = User.current)
        return true if user.easy_lesser_admin_for?(:users) || self.id == user.id

        visibility = Rails.cache.fetch "user_visible_#{user.easy_user_type_id}_#{self.easy_user_type_id}" do
          if user.easy_user_type && self.easy_user_type_id
            user.easy_user_type.easy_user_visible_type_ids.include?(self.easy_user_type_id)
          else
            false
          end
        end

        visibility && visible_without_easy_extensions?(user)
      end

      def highest_role_for_project(project)
        roles_for_project(project).min_by(&:position)
      end

      def remove_references_before_destroy_with_easy_extensions
        remove_references_before_destroy_without_easy_extensions
        substitute = User.anonymous
        EasyQuery.where(user_id: id, visibility: EasyQuery::VISIBILITY_PRIVATE).delete_all
        EasyQuery.where(user_id: id).update_all(user_id: substitute.id)
        EasyQuerySnapshot.where(author_id: id).update_all(author_id: substitute.id)
        EasyQuerySnapshot.where(execute_as_user_id: id).update_all(execute_as_user_id: substitute.id)
        EasyEntityAction.where(author_id: id).update_all(author_id: substitute.id)
        EasyEntityAction.where(execute_as_user_id: id).update_all(execute_as_user_id: substitute.id)
      end

      def is_owner?
        internal_name == 'owner'
      end

      def apply_default_page_template=(apply_default_page_template)
        @apply_default_page_template = apply_default_page_template.to_boolean
      end

      # @note passed username should be uniq to get different colours for 2 users with the same name
      def letter_avatar_path(size)
        LetterAvatar.generate(name.strip + id.to_s, size)
      end

      def initials
        "#{firstname.capitalize[0]}#{lastname.capitalize[0]}"
      end

    end

    module ClassMethods

      def search_results(token, _user, _project, options = {})
        User.visible.active.easy_type_internal.like(token).limit(options[:limit])
      end

      def valid_notification_options_with_easy_extensions(user = nil)
        if user.nil? || user.new_record? || Project.visible(user).size < 1
          User::MAIL_NOTIFICATION_OPTIONS.reject { |option| option.first == 'selected' }
        else
          User::MAIL_NOTIFICATION_OPTIONS
        end
      end

      def try_to_login_with_easy_extensions(login, password, active_only = true)
        login    = login.to_s.strip
        password = password.to_s

        return nil if login.empty? || password.empty?
        user = find_by_login(login)
        if user
          return nil unless user.check_password?(password)
          return nil if !user.active? && active_only
        else
          attrs = AuthSource.authenticate(login, password)
          if attrs
            user          = new(attrs)
            user.login    = login
            user.language = Setting.default_language
            if user.save
              user.reload
              logger.info("User '#{user.login}' created from external auth source: #{user.auth_source.type} - #{user.auth_source.name}") if logger && user.auth_source
            end
          end
        end
        user.update_last_login_on! if user && !user.new_record? && user.active?

        # Update Easy Authentificate digest
        if user && user.logged? && user.easy_digest_token_expired?
          user.send(:update_easy_digest_token, password, true)
        end

        user
      rescue => text
        raise text
      end

      def verify_session_token_with_easy_extensions(user_id, token)
        return false if user_id.blank? || token.blank?

        scope = Token.where(:user_id => user_id, :value => token.to_s, :action => 'session')
        if Setting.session_lifetime?
          scope = scope.where("created_on > ?", Setting.session_lifetime.to_i.minutes.ago)
        end
        if Setting.session_timeout?
          scope = scope.where("updated_on > ?", Setting.session_timeout.to_i.minutes.ago)
        end

        # http://www.redmine.org/issues/29041
        last_updated = scope.maximum(:updated_on)
        if last_updated.nil?
          false
        elsif last_updated <= 1.minute.ago
          scope.update_all(:updated_on => Time.now) == 1
        else
          true
        end
      end

      def load_current_attendance(users)
        a_table       = EasyAttendance.table_name
        current_time  = EasyAttendance.round_time(Time.now)
        beginning_day = Time.now.beginning_of_day
        end_day       = EasyAttendance.round_time(Time.now.end_of_day)

        # There alway be one record per users because of validations
        attendances = EasyAttendance.preload(:easy_attendance_activity).reportable.
            where(user_id: users).
            where("#{a_table}.arrival >= :beginning_day AND #{a_table}.arrival <= :current_time AND " \
                                           "((#{a_table}.departure >= :current_time AND #{a_table}.departure <= :end_day) OR " \
                                           " (#{a_table}.arrival <= :current_time AND #{a_table}.departure IS NULL))",
                  beginning_day: beginning_day, end_day: end_day, current_time: current_time).
            order(:arrival).reverse_order

        users.each do |user|
          attendance = attendances.find { |a| a.user_id == user.id }

          user.instance_variable_set :@current_attendance, attendance
          user.instance_variable_set :@current_attendance_added, true
        end
      end

      def load_last_today_attendance_to_now(users)
        a_table       = EasyAttendance.table_name
        current_time  = EasyAttendance.round_time(Time.now)
        beginning_day = Time.now.beginning_of_day

        # Sometimes there is more records for one users but should occur rarely
        attendances = EasyAttendance.preload(:easy_attendance_activity).reportable.
            where(user_id: users, arrival: beginning_day..current_time).
            order(:arrival)

        users.each do |user|
          attendance = attendances.find { |a| a.user_id == user.id }

          user.instance_variable_set :@last_today_non_work_attendance_to_now, attendance
          user.instance_variable_set :@last_today_non_work_attendance_to_now_added, true
        end
      end

      def owner
        (User.current.internal_name == 'owner' && User.current) || User.active.find_by(internal_name: 'owner') || (User.current.admin? && User.current) || User.active.find_by(admin: true)
      end

    end
  end

  module AnonymousUserPatch

    def self.included(base)
      base.class_eval do
        serialize :easy_lesser_admin_permissions, Array

        def lastname=(value)
          super(value) if new_record?
        end

        def set_default_easy_user_type
          # without easy user type
        end

        def rss_key=(key)
        end
      end
    end
  end

end
EasyExtensions::PatchManager.register_model_patch 'User', 'EasyPatch::UserPatch', :after => 'Principal'
EasyExtensions::PatchManager.register_model_patch 'AnonymousUser', 'EasyPatch::AnonymousUserPatch', :after => 'User'
