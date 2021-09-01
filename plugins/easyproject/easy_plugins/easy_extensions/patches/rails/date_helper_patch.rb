module EasyPatch
  module DateHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def time_ago_in_words_ex(from_time, label_not_expired = '', label_expired = '', include_seconds = false)
          result = time_ago_in_words(from_time + 1.day, :include_seconds => include_seconds)

          if (Time.now - (from_time.to_time + 1.day)) > 0
            "<span>#{label_expired} <span class=\"overdue\">#{result}</span></span>".html_safe
          else
            "<span class=\"date-not-overdue\">#{label_not_expired} <span>#{result}</span></span>".html_safe
          end
        end

      end
    end

    module InstanceMethods

    end

  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActionView::Helpers::DateHelper', 'EasyPatch::DateHelperPatch'
