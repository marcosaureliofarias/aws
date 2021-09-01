module EasyPatch
  module WatchersHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :watcher_link, :easy_extensions

        def quick_watcher_link(object, user)
          return '' if user.nil? || !user.logged? || object.nil? || Watcher.any_watched?([object], user)

          css = [watcher_css(object), 'icon icon-watcher watcher-fav'].join(' ')
          url = watch_path(:object_type => object.class.to_s.underscore, :object_id => object.id)

          link_to content_tag(:span, l(:button_watch), :class => 'tooltip'), url, :remote => true, :method => 'post', :class => css
        end

      end
    end

    module InstanceMethods

      def watcher_link_with_easy_extensions(objects, user, options = {})
        return '' unless user && user.logged?
        objects = Array.wrap(objects)
        return '' unless objects.any?

        watched = Watcher.any_watched?(objects, user)
        if (issues = objects.select { |object| object.is_a?(Issue) }).any?
          if issues.detect { |i| !User.current.allowed_to?(:add_issue_watchers, i.project) }
            return ''
          end
        end

        css = [watcher_css(objects), watched ? 'icon icon-watcher watcher-fav' : 'icon icon-watcher watcher-fav-off'].join(' ')
        css << ' ' << options[:class].to_s if options[:class].present?
        text   = watched ? l(:button_unwatch) : l(:button_watch)
        url    = watch_path(
            :object_type => objects.first.class.to_s.underscore,
            :object_id   => (objects.size == 1 ? objects.first.id : objects.map(&:id).sort)
        )
        method = watched ? 'delete' : 'post'

        link_to text, url, :remote => true, :method => method, :class => css
      end

    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'WatchersHelper', 'EasyPatch::WatchersHelperPatch'
