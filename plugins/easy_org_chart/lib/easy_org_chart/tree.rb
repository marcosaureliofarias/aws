module EasyOrgChart
  class Tree
    attr_reader :users, :root

    class << self
      delegate :root, :users, to: :tree

      def tree
        if EasyOrgChart.installed?
          Rails.cache.fetch('easy_org_chart/tree') { new }
        else
          new([])
        end
      end

      def clear_cache
        Rails.cache.delete 'easy_org_chart/tree'
      end

      def [](user_id)
        users[user_id]
      end

      def ancestor_for(user_id)
        tree_node = tree.users[user_id]
        if tree_node && tree_node.parent
          tree_node.parent.user_id
        end
      end

      def ancestry_for(user_id)
        tree_node = tree.users[user_id]

        tree_node ? tree_node.ancestry_user_ids : []
      end

      def children_for(user_id, related = true)
        tree_node = tree.users[user_id]
        if tree_node
          collection = related ? tree_node.children : tree_node.children_tree
          collection.map(&:user_id)
        else
          []
        end
      end

      def supervisor_user_ids
        root ? root.children_with_children.map(&:user_id) : []
      end
    end

    def initialize(scope = EasyOrgChartNode.order(:lft))
      build_tree(scope)
    end

    def users
      @users ||= {}
    end

    def build_tree(scope)
      id_to_hash = {}

      scope.each do |node|
        tree_node = EasyOrgChart::TreeNode.new(node)

        id_to_hash[node.id] = tree_node
        users[tree_node.user_id] = tree_node

        parent_tree_node = id_to_hash[node.parent_id] || @root
        if parent_tree_node
          tree_node.parent = parent_tree_node
        else
          @root = tree_node
        end
      end
    end
  end
end
