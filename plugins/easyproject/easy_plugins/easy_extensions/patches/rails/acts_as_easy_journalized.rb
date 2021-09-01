module EasyPatch
  module ActsAsEasyJournalized

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      # @option options [Array<String>] :features
      #   refresh_updated_at: update updated_at/on column if journal is created
      def acts_as_easy_journalized(options = {})
        return if self.included_modules.include?(EasyPatch::ActsAsEasyJournalized::EasyJournalizedMethods)

        default_options = {
          non_journalized_columns: %w[id created_on updated_on updated_at created_at lft rgt lock_version],
          delegated_columns: [],
          important_columns: [],
          format_detail_date_columns: [],
          format_detail_time_columns: [],
          format_detail_reflection_columns: [],
          format_detail_boolean_columns: [],
          format_detail_hours_columns: [],
          features: [],
        }

        cattr_accessor :journalized_options
        self.journalized_options = default_options.dup

        options.each do |k, v|
          self.journalized_options[k] = Array(self.journalized_options[k]) | v
        end

        send :include, EasyPatch::ActsAsEasyJournalized::EasyJournalizedMethods
      end

    end

    module EasyJournalizedMethods

      def self.included(base)
        base.class_eval do

          has_many :journals, as: :journalized, dependent: :destroy, inverse_of: :journalized

          attr_reader :current_journal

          if journalized_options[:features].include?('refresh_updated_at')

            before_save do
              if @current_journal
                if self.class.column_names.include?('updated_on')
                  self.updated_on = current_time_from_proper_timezone

                elsif self.class.column_names.include?('updated_at')
                  self.updated_at = current_time_from_proper_timezone
                end
              end
            end

          end

        end
      end

      def clear_current_journal
        @current_journal = nil
      end

      def init_journal(user, notes = '')
        @current_journal ||= Journal.new(journalized: self, user: user, notes: notes)
      end

      def init_system_journal(user, notes = '')
        @current_journal ||= Journal.new(journalized: self, user: user, notes: notes, is_system: true)
      end

      # Returns the names of attributes that are journalized when updating the issue
      def journalized_attribute_names
        (self.class.column_names + self.journalized_options[:delegated_columns]) - self.journalized_options[:non_journalized_columns]
      end

      def as_journal_detail_value
        self.as_json.merge({'class': self.class.name})
      end

      def easy_journal_global_entity_option(option, journal)
        return '' unless journalized_options[:features].include?('use_global_entity_options')
        case option
        when :title
          journal.journalized.to_s
        when :type
          ''
        when :url
          { controller: journal.journalized.class.to_s.underscore.pluralize,
            action: 'show',
            id: journal.journalized_id,
            anchor: "change-#{journal.id}" }
        end
      end

      private

      def create_journal
        @current_journal.save if @current_journal
      end

      def attachment_added(attachment)
        if current_journal && !attachment.new_record?
          current_journal.journalize_attachment(attachment, :added)
        end
      end

      def attachment_removed(attachment)
        if current_journal && !attachment.new_record?
          current_journal.journalize_attachment(attachment, :removed)
          current_journal.save
        end
      end

      def journalize_related_entity_added(entity)
        if current_journal
          entity.save if entity.new_record?
          current_journal.journalize_related_entity_added_or_removed(entity, :added)
        end
      end

      def journalize_related_entity_removed(entity)
        if current_journal
          current_journal.journalize_related_entity_added_or_removed(entity, :removed)
        end
      end

    end
  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActiveRecord::Base', 'EasyPatch::ActsAsEasyJournalized'
