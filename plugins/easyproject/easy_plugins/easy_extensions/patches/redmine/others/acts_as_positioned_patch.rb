module EasyPatch
  module ActsAsPositionedPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        def pk
          self.class.primary_key.try(:to_sym) || :id
        end

        def reorder_to_position=(position)
          self.position = position.to_i
          reset_positions_in_list unless new_record?
        end

        alias_method_chain :insert_position, :easy_extensions
        alias_method_chain :remove_position, :easy_extensions
        alias_method_chain :shift_positions, :easy_extensions
        alias_method_chain :reset_positions_in_list, :easy_extensions

      end
    end

    module InstanceMethods

      def insert_position_with_easy_extensions
        position_scope.where("position >= ? AND #{pk} <> ?", position, send(pk)).update_all('position = position + 1')
      end

      def remove_position_with_easy_extensions
        previous = destroyed? ? position_was : position_before_last_save
        position_scope_was.where("position >= ? AND #{pk} <> ?", previous, send(pk)).update_all("position = position - 1")
      end

      def shift_positions_with_easy_extensions
        offset   = position_before_last_save <=> position
        min, max = [position, position_before_last_save].sort
        r        = position_scope.where("#{pk} <> ? AND position BETWEEN ? AND ?", send(pk), min, max).update_all("position = position + #{offset}")
        if r != max - min
          reset_positions_in_list
        end
      end

      def reset_positions_in_list_with_easy_extensions
        position_scope.reorder(:position, pk).pluck(pk).each_with_index do |record_id, p|
          self.class.where(pk => record_id).update_all(:position => p + 1)
        end
      end

    end
  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Acts::Positioned::InstanceMethods', 'EasyPatch::ActsAsPositionedPatch'
