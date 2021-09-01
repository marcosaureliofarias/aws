module EasyPatch
  module NestedSetTraversingPatch

    def self.included(base)
      base.class_eval do

        class << self

          def included_with_easy_extensions(base)
            base.extend EasyPatch::NestedSetTraversingPatch::ClassMethods

            base.class_eval do
              after_save :set_easy_level
            end

            included_without_easy_extensions(base)
          end

          alias_method_chain :included, :easy_extensions

        end

        def easy_level
          result = read_attribute(:easy_level) if self.class.column_names.include?('easy_level')
          result ||= self.level

          result
        end

        # next methods are from the old awesome_nested_set
        # Returns the level of this object in the tree
        # root level is 0
        def level
          parent_id.nil? ? 0 : compute_level
        end

        def compute_level
          node, nesting = determine_depth

          node == self ? ancestors.count : node.level + nesting
        end

        def determine_depth(node = self, nesting = 0)
          while (association = node.association(:parent)).loaded? && association.target
            nesting += 1
            node    = node.parent
          end if node.respond_to?(:association)

          [node, nesting]
        end

        def set_easy_level(level = self.level)
          return if !self.class.column_names.include?('easy_level') || self.read_attribute(:easy_level) == level
          update_column(:easy_level, level)
          self.children.each { |p| p.set_easy_level(level + 1) }
        end

        # Returns name of the current project with ancestors
        # Params:
        # :separator = string separator between parents and childs
        # :self_only = only self is returned
        # :name_method = method to get the name of an entity
        def family_name(options = {})
          name_method = options[:name_method] || :name
          separator   = options[:separator] || " > "
          prefix      = options[:prefix] || '&nbsp;'
          limit       = options[:max_length]

          s = if options[:self_only]
                (self.child? ? (prefix * 2 * (options[:level] || self.easy_level) + separator) : '') + self.send(name_method)
              else
                if self.child?
                  ancestor_scope = self.self_and_ancestors
                  ancestor_scope = ancestor_scope.select(options[:select]) if options[:select]
                  ancestor_scope = ancestor_scope.joins(options[:joins]) if options[:joins]
                  ancestor_scope = ancestor_scope.where(options[:where]) if options[:where]

                  tree        = ancestor_scope.all.collect do |e|
                    if e.respond_to?(name_method)
                      e.send(name_method)
                    else
                      e.name
                    end
                  end
                  tree_string = tree.join(separator)
                  length      = tree_string.length
                  if limit && length > limit
                    offset      = (tree_string.index(separator) + separator.length + 2)
                    offset      = limit / 2 if offset > limit / 2
                    tree_string = tree_string[0..offset] + '...' + tree_string[(offset + length - limit)..length]
                  end
                  tree_string
                else
                  self.send(name_method)
                end
              end
          s
        end

      end
    end

    module ClassMethods

      def each_with_easy_level(objects, options = {}, &block)
        level_diff = options[:zero_start] ? objects.first.easy_level : 0
        objects.each do |o|
          yield(o, o.easy_level - level_diff)
        end
      end

      def each_with_level(objects, with_ancestors = false, &block)
        path = [nil]
        objects.each do |o|
          if o.parent_id != path.last
            # we are on a new level, did we decent or ascent?
            if path.include?(o.parent_id)
              # remove wrong wrong tailing paths elements
              path.pop while path.last != o.parent_id
            else
              path << o.parent_id
            end
          end
          if with_ancestors
            yield(o, path.length - 1, path.compact)
          else
            yield(o, path.length - 1)
          end
        end
      end

      def quoted_left_column_name
        self.connection.quote_column_name 'lft'
      end

      def quoted_right_column_name
        self.connection.quote_column_name 'rgt'
      end

    end

  end
end

module EasyPatch
  module ProjectNestedSetPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do

        alias_method_chain :destroy_children, :easy_extensions

      end
    end

    module InstanceMethods

      def destroy_children_with_easy_extensions
        unless @without_nested_set_update
          lock_nested_set
          reload_nested_set_values
        end
        children.each { |c| c.send :destroy_without_nested_set_update }
        unless @without_nested_set_update
          return false unless rgt && lft
          self.class.where('lft > ? OR rgt > ?', lft, lft).update_all([
                                                                          'lft = CASE WHEN lft > :lft THEN lft - :shift ELSE lft END, ' +
                                                                              'rgt = CASE WHEN rgt > :lft THEN rgt - :shift ELSE rgt END',
                                                                          { lft: lft, shift: rgt - lft + 1 }
                                                                      ])
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_concern_patch 'Redmine::NestedSet::Traversing', 'EasyPatch::NestedSetTraversingPatch'
EasyExtensions::PatchManager.register_concern_patch 'Redmine::NestedSet::ProjectNestedSet', 'EasyPatch::ProjectNestedSetPatch'
