module EasyKnowledge
  module EasyKnowledgeCategoryNestedSet
    def self.included(base)
      base.class_eval do
        belongs_to :parent, :class_name => self.name

        before_create :add_to_nested_set
        before_update :move_in_nested_set, :if => lambda {|category| category.parent_id_changed? || category.name_changed?}
        before_destroy :destroy_children
      end
      base.extend ClassMethods
      base.send :include, Redmine::NestedSet::Traversing
    end

    private

    def target_lft
      siblings_rgt = self.class.where(:parent_id => parent_id).where("name < ?", name).maximum(:rgt)
      if siblings_rgt
        siblings_rgt + 1
      elsif parent_id
        parent_lft = self.class.where(:id => parent_id).pluck(:lft).first
        raise "#{self.class} id=#{id} with parent_id=#{parent_id}: parent missing or without 'lft' value" unless parent_lft
        parent_lft + 1
      else
        1
      end
    end

    def add_to_nested_set(lock=true)
      lock_nested_set if lock
      self.lft = target_lft
      self.rgt = lft + 1
      self.class.where("lft >= ? OR rgt >= ?", lft, lft).update_all([
        "lft = CASE WHEN lft >= :lft THEN lft + 2 ELSE lft END, " +
        "rgt = CASE WHEN rgt >= :lft THEN rgt + 2 ELSE rgt END",
        {:lft => lft}
      ])
    end

    def move_in_nested_set
      lock_nested_set
      reload_nested_set_values
      a = lft
      b = rgt
      c = target_lft
      unless c == a
        if c > a
          # Moving to the right
          d = c - (b - a + 1)
          scope = self.class.where(["lft BETWEEN :a AND :c - 1 OR rgt BETWEEN :a AND :c - 1", {:a => a, :c => c}])
          scope.update_all([
            "lft = CASE WHEN lft BETWEEN :a AND :b THEN lft + (:d - :a) WHEN lft BETWEEN :b + 1 AND :c - 1 THEN lft - (:b - :a + 1) ELSE lft END, " +
            "rgt = CASE WHEN rgt BETWEEN :a AND :b THEN rgt + (:d - :a) WHEN rgt BETWEEN :b + 1 AND :c - 1 THEN rgt - (:b - :a + 1) ELSE rgt END",
            {:a => a, :b => b, :c => c, :d => d}
          ])
        elsif c < a
          # Moving to the left
          scope = self.class.where("lft BETWEEN :c AND :b OR rgt BETWEEN :c AND :b", {:a => a, :b => b, :c => c})
          scope.update_all([
            "lft = CASE WHEN lft BETWEEN :a AND :b THEN lft - (:a - :c) WHEN lft BETWEEN :c AND :a - 1 THEN lft + (:b - :a + 1) ELSE lft END, " +
            "rgt = CASE WHEN rgt BETWEEN :a AND :b THEN rgt - (:a - :c) WHEN rgt BETWEEN :c AND :a - 1 THEN rgt + (:b - :a + 1) ELSE rgt END",
            {:a => a, :b => b, :c => c, :d => d}
          ])
        end
        reload_nested_set_values
      end
    end

    def destroy_children
      if @with_nested_set_update
        lock_nested_set
        @with_nested_set_update = !!reload_nested_set_values
      end
      children.each {|c| c.send :destroy_without_nested_set_update}
      if @with_nested_set_update
        self.class.where("lft > ? OR rgt > ?", lft, lft).update_all([
          "lft = CASE WHEN lft > :lft THEN lft - :shift ELSE lft END, " +
          "rgt = CASE WHEN rgt > :lft THEN rgt - :shift ELSE rgt END",
          {:lft => lft, :shift => rgt - lft + 1}
        ])
      end
    end

    def destroy_without_nested_set_update
      @with_nested_set_update = false
      destroy
    end

    def reload_nested_set_values
      self.lft, self.rgt = self.class.where(:id => id).pluck(:lft, :rgt).first
    end

    def save_nested_set_values
      self.class.where(:id => id).update_all(:lft => lft, :rgt => rgt)
    end

    def move_possible?(category)
      new_record? || !is_or_is_ancestor_of?(category)
    end

    def lock_nested_set
      self.class.order(:id).lock(true).ids
    end

    def nested_set_scope
      self.class.order(:lft)
    end

    def same_nested_set_scope?(category)
      true
    end

    module ClassMethods
      def rebuild_tree!
        transaction do
          reorder(:id).lock.ids
          update_all(:lft => nil, :rgt => nil)
          rebuild_nodes
        end
      end

      private

      def rebuild_nodes(parent_id = nil)
        nodes = self.where(:parent_id => parent_id).where(:rgt => nil, :lft => nil).reorder(:name)

        nodes.each do |node|
          node.send :add_to_nested_set, false
          node.send :save_nested_set_values
          rebuild_nodes node.id
        end
      end
    end
  end
end
