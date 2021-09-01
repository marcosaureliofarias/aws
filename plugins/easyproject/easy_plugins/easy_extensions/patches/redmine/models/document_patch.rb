module EasyPatch
  module DocumentPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        html_fragment :description, :scrub => :strip

        acts_as_restricted :restricted_object => :category, :easy_permission_name => :read
        acts_as_customizable
        acts_as_user_readable

        searchable_options[:scope]   = Document.joins(:project).where(:projects => { :easy_is_easy_template => false })
        searchable_options[:preload] = [:project, :attachments]

        event_options[:description] = Proc.new { |o| o.description.to_s }

        safe_attributes 'custom_field_values'

        alias_method_chain :recipients, :easy_extensions
        alias_method_chain :attachments_visible?, :easy_extensions
        alias_method_chain :attachments_editable?, :easy_extensions
        alias_method_chain :attachments_deletable?, :easy_extensions
        alias_method_chain :visible?, :easy_extensions
        alias_method_chain :to_s, :easy_extensions

        def self.fields_for_order_statement(table = nil)
          table ||= table_name
          ["#{table}.title"]
        end

      end
    end

    module InstanceMethods

      def to_s_with_easy_extensions
        self.title
      end

      def attachments_visible_with_easy_extensions?(user = User.current)
        attachments_visible_without_easy_extensions?(user) && !self.active_record_restricted?(user, :read)
      end

      def attachments_editable_with_easy_extensions?(user = User.current)
        visible?(user) && User.current.allowed_to?({controller: 'documents', action: 'add_attachment'}, self.project) && !self.active_record_restricted?(user, :manage)
      end

      def attachments_deletable_with_easy_extensions?(user = User.current)
        attachments_deletable_without_easy_extensions?(user) && !self.active_record_restricted?(user, :manage)
      end

      def visible_with_easy_extensions?(user = User.current)
        visible_without_easy_extensions?(user) && !self.active_record_restricted?(user, [:read, :manage])
      end

      def recipients_with_easy_extensions
        project.users.where.not(:mail_notification => 'none').select { |user| visible?(user) }
      end

      def editable?(user = User.current)
        user.allowed_to?(:edit_documents, self.project)
      end

      def deletable?(user = User.current)
        user.allowed_to?(:delete_documents, self.project)
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Document', 'EasyPatch::DocumentPatch'
