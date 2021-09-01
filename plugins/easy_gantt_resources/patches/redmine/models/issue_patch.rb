module EasyGanttResources
  module IssuePatch

    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)

      base.class_eval do
        has_one :custom_resource_allocator, class_name: 'EasyIssueAllocator', foreign_key: 'issue_id', autosave: true, dependent: :delete

        before_save :prepare_reallocate_resources
        after_save :reallocate_resources

        safe_attributes 'custom_resource_allocator_name', if: proc {|issue, user| issue.attributes_editable?(user) }

        scope :easy_gantt_resource_between, lambda { |from, to|
          tbl = Issue.table_name
          where("
            (#{tbl}.start_date >= :from AND #{tbl}.start_date <= :to) OR
            (#{tbl}.due_date >= :from AND #{tbl}.due_date <= :to) OR
            (#{tbl}.start_date <= :from AND #{tbl}.due_date >= :to)
          ", from: from, to: to)
        }

        scope :with_easy_gantt_resources, lambda { |from=nil, to=nil|
          if from.nil? && to.nil?
            return
          end

          i_table = Issue.table_name
          r_table = EasyGanttResource.table_name

          cond = []
          cond << "r.date >= :from" if from
          cond << "r.date <= :to" if to
          cond = cond.join(' AND ')

          where("EXISTS(SELECT 1 FROM #{r_table} r
                        WHERE r.issue_id = #{i_table}.id AND r.hours > 0 AND (#{cond}))", from: from, to: to)
        }

        # Dirty hack but if something call .reload in after_save callback -> all changes are lost.
        # See: nested set or notification sending
        def prepare_reallocate_resources
          @__alloc_changes = changes.keys & ['assigned_to_id', 'start_date', 'due_date', 'estimated_hours', 'status_id']

          if @custom_resource_allocator_changed
            @__alloc_changes << 'custom_resource_allocator'
          end
        end

        def reallocate_resources
          # Nothing change
          if @__alloc_changes && @__alloc_changes.empty?
            return
          end

          # Only status changed
          #   o -> o  nothing
          #   o -> c  delete
          #   c -> o  reallocation
          #   c -> c  nothing
          if @__alloc_changes == ['status_id']
            if closed? == was_closed?
              return
            end

            if closed?
              easy_gantt_resources.delete_all
              return
            end
          end

          # Required attributes was changed and are usable
          if allocable?
            allocator = EasyGanttResources::IssueAllocator.get(self)
            allocator.recalculate!

          # Something was "unset"
          else
            easy_gantt_resources.delete_all
          end
        end

        def allocable?
          project.try(:easy_baseline_for_id).nil? &&
          !project.try(:easy_is_easy_template?) &&
          (start_date.present? || due_date.present?) &&
          estimated_hours.present? &&
          estimated_hours >= 0 &&
          !closed?
        end

      end
    end

    module InstanceMethods

      def allocated_hours
        @allocated_hours ||= EasyGanttResource.where(issue_id: id).sum(:hours)
      end

      def custom_resource_allocator_enabled?
        EasySetting.value(:easy_gantt_resources_change_allocator_enabled, project_id)
      end

      def resource_allocator
        if custom_resource_allocator_enabled?
          name = custom_resource_allocator_name
        end

        name || EasySetting.value(:easy_gantt_resources_default_allocator, project_id)
      end

      def custom_resource_allocator_name
        if custom_resource_allocator_enabled? &&
           custom_resource_allocator &&
           custom_resource_allocator.persisted?
          custom_resource_allocator.allocator
        end
      end

      def custom_resource_allocator_name=(name)
        return unless custom_resource_allocator_enabled?

        name = name.presence
        if custom_resource_allocator_name != name
          if name
            alloc = custom_resource_allocator || build_custom_resource_allocator
            alloc.allocator = name
          else
            custom_resource_allocator.mark_for_destruction
          end

          @custom_resource_allocator_changed = true
        end
      end

    end

    module ClassMethods

      def load_allocated_hours(issues)
        all_hours = EasyGanttResource.where(issue_id: issues.map(&:id)).group(:issue_id).sum(:hours)

        issues.each do |issue|
          hours = all_hours[issue.id] || 0
          issue.instance_variable_set(:@allocated_hours, hours)
        end
      end

    end

  end
end
RedmineExtensions::PatchManager.register_model_patch 'Issue', 'EasyGanttResources::IssuePatch'
