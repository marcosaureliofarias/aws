# encoding: utf-8
module EasyPatch
  module PaginatorPatch
    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :initialize, :easy_extensions
        alias_method_chain :offset, :easy_extensions
        alias_method_chain :last_page, :easy_extensions
        alias_method_chain :last_item, :easy_extensions
        alias_method_chain :first_item, :easy_extensions
        alias_method_chain :multiple_pages?, :easy_extensions

      end
    end

    module InstanceMethods

      def initialize_with_easy_extensions(*args)
        initialize_without_easy_extensions(*args)
        @show_all = @per_page.nil?
      end

      def offset_with_easy_extensions
        return nil if @show_all
        offset_without_easy_extensions
      end

      def last_page_with_easy_extensions
        return 1 if @show_all
        last_page_without_easy_extensions
      end

      def last_item_with_easy_extensions
        return item_count if @show_all
        last_item_without_easy_extensions
      end

      def first_item_with_easy_extensions
        return 1 if @show_all
        first_item_without_easy_extensions
      end

      def multiple_pages_with_easy_extensions?
        return false if @show_all
        multiple_pages_without_easy_extensions?
      end

    end

  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Pagination::Paginator', 'EasyPatch::PaginatorPatch'
