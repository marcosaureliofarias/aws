module EasyResourceBase
  module PrincipalPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.extend(ClassMethods)

      resource_association = proc do
        has_many :easy_gantt_resources, foreign_key: 'user_id',  dependent: :destroy
      end

      Principal.class_eval(&resource_association)
      User.class_eval(&resource_association)
      Group.class_eval(&resource_association)
    end

    module InstanceMethods

      def easy_resources_sums(from, to, **options)
        self.class.easy_resources_sums([self], from, to, **options)[id].to_h
      end

    end

    module ClassMethods

      def easy_resources_sums(users, from, to, except_issue_ids: nil, all_statuses: nil, include_reservations: true, except_reservation_ids: [], include_issues: true)
        return {} if users.blank?

        # Through API there is only ids
        user_ids = users.first.is_a?(Principal) ? users.map(&:id) : users

        # Must distinguish between User and Group
        groups_users = Principal.from('groups_users').where(groups_users: { group_id: user_ids }).pluck(:user_id, :group_id)

        # User can be part of group but does not have to be part of requested users
        groups_users.each {|id, _| user_ids << id }
        user_ids.uniq!

        # sums[USER][DATE] = HOURS
        sums = Hash.new { |hash1, key1|
          hash1[key1] = Hash.new { |hash2, key2|
            hash2[key2] = 0
          }
        }
        if include_issues
          scope = EasyGanttResource.non_templates.where(user_id: user_ids).
            where('hours > 0').
            between_dates(from, to)

          if !all_statuses
            scope = scope.active_and_planned
          end

          if except_issue_ids
            scope = scope.where.not(issue_id: Array(except_issue_ids))
          end

          if block_given?
            scope = yield scope
          end

          scope = scope.group(:user_id, :date).sum(:hours)
          scope.each do |(user_id, date), hours|
            sums[user_id][date] = hours
          end
        end
        if include_reservations && EasySetting.value(:easy_gantt_resources_reservation_enabled) && defined?(EasyGanttReservationResource)
          reservations = EasyGanttReservationResource.joins(:reservation).
            where(easy_gantt_reservations: { assigned_to_id: user_ids }).
            where('hours > 0').
            where.not(easy_gantt_reservations: { id: except_reservation_ids} ).
            between_dates(from, to).
            pluck('easy_gantt_reservations.assigned_to_id',
              'easy_gantt_reservation_resources.date',
              'easy_gantt_reservation_resources.hours')
          reservations.each do |(user_id, date, hours)|
            sums[user_id][date] += hours
          end
        end

        # Add user hours to group where he is part of
        groups_users.each do |user_id, group_id|
          user_data = sums[user_id]
          user_data.each do |date, hours|
            sums[group_id][date] += hours
          end
        end

        sums
      end

      def easy_resources_planned_sums(*args)
        return {} unless Project.const_defined?(:STATUS_PLANNED)

        args = args.dup

        if args.last.is_a?(Hash)
          args.last[:all_statuses] = true
        else
          args << { all_statuses: true }
        end

        easy_resources_sums(*args){ |scope|
          scope.joins(issue: :project).where("#{Project.table_name}.status = ?", Project::STATUS_PLANNED)
        }
      end

    end

  end
end
RedmineExtensions::PatchManager.register_model_patch 'Principal', 'EasyResourceBase::PrincipalPatch'
