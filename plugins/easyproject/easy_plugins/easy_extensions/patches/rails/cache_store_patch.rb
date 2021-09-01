module EasyPatch
  module ActiveSupport
    module StorePatch

      def easy_fetch_if(condition, *args, &block)
        if condition
          fetch(*args, &block)
        else
          yield
        end
      end

    end
  end
end
RedmineExtensions::PatchManager.register_rails_patch 'ActiveSupport::Cache::Store', 'EasyPatch::ActiveSupport::StorePatch'
