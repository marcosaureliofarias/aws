module EasyCalendar
  module RedmineNotifiablePatch

    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do
        class << self
          alias_method_chain :all, :easy_calendar
        end
      end
    end

    module ClassMethods

      def all_with_easy_calendar
        n = all_without_easy_calendar
        n << Redmine::Notifiable.new('meeting')
        n
      end

    end

  end

end

EasyExtensions::PatchManager.register_other_patch 'Redmine::Notifiable', 'EasyCalendar::RedmineNotifiablePatch'
