module EasyOrgChart
  class TreeNode
    attr_reader :parent, :children, :node

    delegate :user_id, :user, to: :node

    def initialize(easy_org_chart_node)
      @children = []
      @node = easy_org_chart_node
    end

    def parent=(tree_node)
      tree_node.children << self
      @parent = tree_node
    end

    def ancestry
      Array.new.tap do |ancestors_list|
        current_node = self

        while current_node.parent
          current_node = current_node.parent
          ancestors_list << current_node
        end

      end
    end

    def ancestry_user_ids
      ancestry.map(&:user_id)
    end

    def children_tree
      Array.new.tap do |nodes|
        children.each do |node|
          nodes << node
          nodes.concat node.children_tree
        end
      end
    end

    def children_with_children
      nodes = []
      if children.any?
        nodes << self

        children.each do |node|
          nodes += node.children_with_children
        end
      end

      nodes
    end

    def inspect
      "<#{self.class}: @user_id=#{user_id}>"
    end
  end
end
