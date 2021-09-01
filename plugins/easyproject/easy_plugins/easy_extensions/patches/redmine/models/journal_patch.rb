module EasyPatch
  module JournalPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        has_many :easy_permissions, :as => :entity, :class_name => 'EasyPermission'

        include EasyExtensions::EasyInlineFragmentStripper
        html_fragment :notes, :scrub => :strip
        strip_inline_images :notes

        attr_accessor :notify_children, :is_copy

        before_save :cancel_save
        after_initialize :default_values
        # after_initialize :gsub_note_from_textile
        after_create :copy_journal_to_parent_and_children, :if => Proc.new { |journal|
          journal.journalized_type == 'Issue' && journal.issue.present? && !journal.issue.mass_operations_in_progress && journal.notes.present? }
        after_commit :send_mentions_notification, if: -> { notes.present? }

        alias_method_chain :cache_key, :easy_extensions
        alias_method_chain :notified_users, :easy_extensions
        alias_method_chain :notified_watchers, :easy_extensions
        alias_method_chain :send_notification, :easy_extensions
        alias_method_chain :journalize_changes, :easy_extensions
        alias_method_chain :visible_details, :easy_extensions
        alias_method_chain :start, :easy_extensions
        alias_method_chain :css_classes, :easy_extensions
        alias_method_chain :editable_by?, :easy_extensions

        scope :with_notes, -> { where("LENGTH(notes) > 0") }
        scope :non_system, -> { where(is_system: false) }

        # change acts_as_event params
        Journal.event_options = {
            :datetime    => :created_on,
            :title       => Proc.new { |o| o.easy_journal_option(:title) },
            :description => :notes,
            :author      => :user,
            :type        => Proc.new { |o| o.easy_journal_option(:type) },
            :url         => Proc.new { |o| o.easy_journal_option(:url) },
            :group       => :easy_journal_event_group
        }

        def default_values
          if new_record?
            begin
              ; self.created_on ||= DateTime.now;
            rescue;
            end
          end
        end

        def cancel_save
          false if self.project && self.project.easy_is_easy_template?
        end

        def copy_journal_to_parent_and_children
          issues_for_copy = []
          if self.issue.parent && self.issue.parent.tracker.easy_distributed_tasks? && !self.issue.tracker.easy_distributed_tasks?
            issues_for_copy << self.issue.parent
            issues_for_copy.concat(self.issue.siblings)
          elsif self.issue.tracker.easy_distributed_tasks?
            issues_for_copy.concat(self.issue.children)
          end

          issues_for_copy.each { |i| self.copy_to_issue(i) }
        end

        def copy_to_issue(i)
          self_copy                                   = dup
          self_copy.issue                             = i
          self_copy.is_copy                           = true
          self_copy.issue.mass_operations_in_progress = true
          self_copy.save
          copy_details(self_copy)
        end

        def copy_details(target_journal)
          details.each do |detail|
            dup_detail         = detail.dup
            dup_detail.journal = target_journal
            dup_detail.save
          end
        end

        def important_details_map
          important_columns = self.journalized.journalized_options[:important_columns]
          self.visible_details.map { |detail| (detail.property == 'attr' && important_columns.include?(detail.prop_key)) || detail.property == 'attachment' }
        end

        def not_important_details?
          self.important_details_map.include?(false)
        end

        def important_details?
          self.important_details_map.include?(true)
        end

        def send_mentions_notification
          mentions = find_mentions.to_a
          EasyJournalMailer.deliver_mentioned(mentions, self) if mentions.any?
        end

        private

        def find_mentions
          notes.present? ? User.active.non_system_flag.where(login: notes.scan(/@([A-Za-z0-9_\-@\.]*)/).flatten) : []
        end

        def attach_stripped_image(filename, file, extension)
          journalized.attachments.create(
              :file         => file,
              :filename     => filename,
              :author       => User.current,
              :description  => !!EasySetting.value('attachment_description_required') && '*' || '',
              :content_type => "image/#{extension}") if journalized.respond_to?(:attachments) && journalized.attachments.respond_to?(:create)
        end

      end
    end

    module InstanceMethods

      def css_classes_with_easy_extensions
        s = 'journal'
        s << ' has-notes' if notes.present? && !is_system?
        s << ' has-details' if details.present? || is_system?
        s << ' private-notes' if private_notes?
        s
      end

      def editable_by_with_easy_extensions?(usr)
        return false if is_system?

        editable_by_without_easy_extensions?(usr)
      end

      def cache_key_with_easy_extensions
        if new_record?
          'journals/new'
        else
          "journals/#{id}-#{created_on.strftime('%Y%m%d%H%M%S')}"
        end
      end

      def notified_users_with_easy_extensions
        notified = notified_users_without_easy_extensions

        additional_notified_filter(notified)
      end

      def notified_watchers_with_easy_extensions
        notified = notified_watchers_without_easy_extensions

        additional_notified_filter(notified)
      end

      def send_notification_with_easy_extensions
        return unless send_email_notifications?

        send_notification_without_easy_extensions
        self.journalized.notification_sent = true
      end

      def send_email_notifications?
        return false unless self.journalized.is_a?(Issue)
        return false if self.user && self.user.pref.no_notification_ever
        return false unless self.notify?
        return false unless send_email_notification_after_change_from_subtask?
        return false unless (Setting.notified_events.include?('issue_updated') ||
            (Setting.notified_events.include?('issue_note_added') && self.notes.present? && !self.is_system) ||
            (Setting.notified_events.include?('issue_status_updated') && self.new_status.present?) ||
            (Setting.notified_events.include?('issue_assigned_to_updated') && detail_for_attribute('assigned_to_id').present?) ||
            (Setting.notified_events.include?('issue_priority_updated') && self.new_value_for('priority_id').present?) ||
            (Setting.notified_events.include?('issue_fixed_version_updated') && detail_for_attribute('fixed_version_id').present?))

        true
      end

      def send_email_notification_after_change_from_subtask?
        automatic_note = self.notes.present? && self.is_system
        return false unless (!automatic_note ||
            Setting.notified_events.include?('issue_updated') ||
            (Setting.notified_events.include?('issue_priority_updated') && self.new_value_for('priority_id').present?))
        true
      end

      def visible_details_with_easy_extensions(user = User.current)
        visible_details_without_easy_extensions(user).reject do |detail|
          if detail.prop_key == 'estimated_hours' && detail.property == 'attr'
            !user.allowed_to?(:view_estimated_hours, project)
          elsif detail.property == 'attr'
            !journalized.journalized_attribute_names.include?(detail.prop_key)
          else
            false
          end
        end
      end

      def notify_visible_details(user = User.current)
        details           = visible_details(user)
        cf_detail_ids     = details.map { |detail| detail.prop_key if detail.property == 'cf' }
        non_notify_cf_ids = CustomField.where(mail_notification: false, id: cf_detail_ids).pluck(:id)
        details.reject { |detail| detail.property == 'cf' && non_notify_cf_ids.include?(detail.prop_key.to_i) }
      end

      def start_with_easy_extensions
        if journalized
          @attributes_before_change    = journalized.journalized_attribute_names.inject({}) do |h, attribute|
            h[attribute] = journalized.send(attribute)
            h
          end
          @custom_values_before_change = journalized.custom_field_values.inject({}) do |h, c|
            h[c.custom_field_id] = c.value
            h
          end if journalized.respond_to?(:custom_field_values)
        end
        self
      end

      def easy_journal_event_group
        if journalized && journalized.respond_to?(:easy_journal_event_group)
          return journalized.send(journalized.easy_journal_event_group)
        end
        journalized || self
      end

      def easy_journal_option(option)
        if journalized && journalized.respond_to?(:easy_journal_option)
          journalized.easy_journal_option(option, self)
        elsif journalized && journalized.respond_to?(:easy_journal_global_entity_option)
          journalized.easy_journal_global_entity_option(option, self)
        else
          ''
        end
      end

      def additional_notified_filter(notified = [])
        if notify_children && issue
          notified = issue.children.inject([]) do |users, issue|
            users << Array.wrap(issue.assigned_to.is_a?(Group) ? issue.assigned_to.users : issue.assigned_to).flatten.select { |user| user && user.notify_about?(issue) }
          end
          notified.concat(issue.notified_users)
          notified.concat(issue.notified_watchers)
          notified.flatten!
          notified.compact!
          notified.uniq!(&:id)
          notified
        else
          return notified unless self.details.count == 1

          details = self.details.first
          if details.property == 'relation' && details.value.present?
            entity   = self.journalized_type.constantize.find(details.value)
            notified = notified.select { |user| entity.visible?(user) }
          end
        end
        notified
      rescue ActiveRecord::RecordNotFound
        notified
      end

      def journalize_related_entity_added_or_removed(entity, added_or_removed)
        key = (added_or_removed == :removed ? :old_value : :value)
        details << JournalDetail.new(
            :property => 'entity',
            :prop_key => entity.id,
            key => (entity.respond_to?(:as_journal_detail_value) ? entity.as_journal_detail_value : entity).to_json
          )
      end

      private

      def journalize_changes_with_easy_extensions
        return false if is_copy
        # attributes changes
        if @attributes_before_change
          attrs = (journalized.journalized_attribute_names + @attributes_before_change.keys).uniq
          attrs.each do |attribute|
            before = @attributes_before_change[attribute]
            after  = journalized.send(attribute)
            next if before == after || (before.blank? && after.blank?) || (attribute.to_s == 'description' && Sanitize.clean(before.to_s, :output => :html).strip == Sanitize.clean(after.to_s, :output => :html).strip)
            add_attribute_detail(attribute, before, after)
          end
        end
        # custom fields changes
        if @custom_values_before_change
          values_by_custom_field_id = {}
          @custom_values_before_change.each do |custom_field_id, value|
            values_by_custom_field_id[custom_field_id] = nil
          end
          journalized.custom_field_values.each do |c|
            next if c.custom_field.field_format == 'easy_rating'
            values_by_custom_field_id[c.custom_field_id] = c.value
          end

          values_by_custom_field_id.each do |custom_field_id, after|
            before = @custom_values_before_change[custom_field_id]
            next if before == after || (before.blank? && after.blank?)

            if before.is_a?(Array) || after.is_a?(Array)
              before = [before] unless before.is_a?(Array)
              after  = [after] unless after.is_a?(Array)

              # values removed
              (before - after).reject(&:blank?).each do |value|
                add_custom_field_detail(custom_field_id, value, nil)
              end
              # values added
              (after - before).reject(&:blank?).each do |value|
                add_custom_field_detail(custom_field_id, nil, value)
              end
            else
              add_custom_field_detail(custom_field_id, before, after)
            end
          end
        end
        start
      end

    end

    module ClassMethods

      def easy_activity_custom_project_scope(scope, options, event_type)
        entity_class = begin
          ; event_type.singularize.camelcase.constantize rescue nil;
        end
        if entity_class && entity_class.column_names.include?('project_id')
          scope.where("#{entity_class.table_name}.project_id in (?)", options[:project_ids])
        else
          self.none
        end
      end

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Journal', 'EasyPatch::JournalPatch'
