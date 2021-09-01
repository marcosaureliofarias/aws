module EasyOrgChart
  module UserPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        class << self
          alias_method_chain :additional_select_options, :easy_org_chart
        end

        has_one :easy_org_chart_node, dependent: :destroy
        has_one :parent_easy_org_chart_node, class_name: 'EasyOrgChartNode', through: :easy_org_chart_node, source: :parent
        has_one :supervisor, class_name: 'User', through: :parent_easy_org_chart_node, source: :user

        validate :check_supervisor, if: :supervisor_changed?


        safe_attributes 'supervisor_user_id',
                        if: -> _, current_user { current_user.easy_lesser_admin_for?(:users) }

        after_save :update_org_chart, if: :supervisor_changed?

        scope :without_org_chart, -> *user_ids {
          subquery = EasyOrgChartNode.select(:user_id).where.not(user_id: user_ids)
          where.not(id: subquery)
        }
      end
    end

    module InstanceMethods
      def supervisor_user_id
        defined?(@supervisor_user_id) ? @supervisor_user_id : EasyOrgChart::Tree.ancestor_for(id)
      end

      def supervisor_user_id=(value)
        @supervisor_user_id = value.present? ? value.to_i : nil
      end

      def supervisor_changed?
        supervisor_user_id != EasyOrgChart::Tree.ancestor_for(id)
      end

      def root_supervisor?
        EasyOrgChart::Tree.children_for(id).any? && !EasyOrgChart::Tree.ancestor_for(id)
      end

      def check_supervisor
        if persisted? && supervisor_user_id.blank? && EasyOrgChart::Tree.children_for(id).any?
          errors.add :supervisor_user_id, :children_exists
        end

        if supervisor_user_id.present?
          if EasyOrgChart::Tree.users.except(id).any? && !EasyOrgChart::Tree[supervisor_user_id]
            errors.add :supervisor_user_id, :missing_in_tree
          end

          if root_supervisor?
            errors.add :supervisor_user_id, :root_changed
          end

          if supervisor_user_id == id
            errors.add :supervisor_user_id, :invalid
          end
        end
      end

      def update_org_chart
        if supervisor_user_id.present?
          if EasyOrgChart::Tree.users.except(id).any?
            parent_node = EasyOrgChartNode.find_by(user_id: supervisor_user_id)
          else
            parent_node = EasyOrgChartNode.create!(user_id: supervisor_user_id)
          end

          if parent_node
            node = easy_org_chart_node || build_easy_org_chart_node
            node.parent = parent_node
            node.save
          end
        else
          easy_org_chart_node.try(:destroy)
        end

        EasyOrgChart::Tree.clear_cache
      end

      def allowed_to_view_subordinates_options?
        return true if admin? || allowed_to_globally?(:manage_custom_dashboards) || allowed_to_globally?(:manage_public_queries)
        EasyOrgChart::Tree.supervisor_user_ids.include?(id)
      end

    end

    module ClassMethods
      def additional_select_options_with_easy_org_chart
        options = additional_select_options_without_easy_org_chart || {}

        if User.current.logged? && User.current.allowed_to_view_subordinates_options?
          options.merge!(Hash[::AddMySubordinatesToUsersList.call([])])
        end

        options
      end

      def add_my_subordinates_options(values)
        if User.current.logged? && User.current.allowed_to_view_subordinates_options?
          ::AddMySubordinatesToUsersList.call(values)
        end
      end

      def subordinates_access_permissions
        [:forbidden, :direct_subordinates, :subordinates_tree]
      end
    end
  end

end

RedmineExtensions::PatchManager.register_model_patch 'User', 'EasyOrgChart::UserPatch'
