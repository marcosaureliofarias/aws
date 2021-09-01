module EasyPatch
  module AttachmentPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do
        belongs_to :project
        belongs_to :document, class_name: 'Document', foreign_key: 'container_id'
        has_many :versions, class_name: 'AttachmentVersion', dependent: :destroy
        validates :description, :presence => true, :if => :description_required?
        attr_writer :skip_description_required

        safe_attributes 'project_id'

        acts_as_restricted :restricted_object => :container, :easy_permission_name => [:read, :manage],
                           :if                => Proc.new { |att| att.container_type == 'Document' }

        acts_as_user_readable
        acts_as_customizable

        skip_callback :validate, :before, :validate_custom_field_values, :if => :new_record?
        skip_callback :save, :after, :save_custom_field_values, :if => :not_attached?

        alias_method_chain :sanitize_filename, :easy_extensions
        alias_method_chain :validate_max_file_size, :easy_extensions
        alias_method_chain :increment_download, :easy_extensions

        before_save :set_project_id_from_container
        before_save :set_new_version
        after_save :create_version, :if => Proc.new { |p| !p.container_id.nil? }

        scope :visible_for_query, lambda { |user = User.current|
          joins(:project).where(Attachment.visible_condition(user))
        }

        def initialize(*args)
          super
          if new_record?
            self.version = 1
          end
        end

        class << self

          alias_method_chain :update_digests_to_sha256, :easy_extensions

          def sanitize_filename(value)
            # get only the filename, not the whole path
            just_filename = value.gsub(/\A.*(\\|\/)/m, '')

            # Finally, replace invalid characters with underscore
            just_filename.gsub(/[\/\?\%\*\:\|\"\'<>\n\r]+/, '_')
          end

          def attachment_reminder_words
            '(^|\\W)(' + EasySetting.value('attachment_reminder_words').gsub(/[\n,;]/, '|').tr(" \t\r", '').gsub(/\?/, '.?').gsub(/\*/, '.*').tr_s('|', '|').chomp('|') + ')($|\\W)'
          end

        end

        def reuse_existing_file_if_possible
          # ignore
        end

        def current_version
          return @current_version if @current_version
          @current_version ||= self.versions.detect { |v| v.version == self.version }
          @current_version ||= self.versions.last
          @current_version ||= AttachmentVersion.new
          return @current_version
        end

        def description_required?
          !!EasySetting.value('attachment_description_required') && !@skip_description_required
        end

        def editable?(user = User.current)
          if container_id
            container && container.attachments_editable?(user)
          else
            author == user
          end
        end

        def is_message?
          Redmine::MimeType.is_type?('message', filename)
        end

        def not_attached?
          container.nil?
        end

      end
    end

    module InstanceMethods

      def validate_max_file_size_with_easy_extensions
        if self.filesize > Setting.attachment_max_size.to_i.kilobytes
          errors.add(:base, :too_long, :count => Setting.attachment_max_size.to_i.kilobytes, :message => self.filename + ' - ' + l(:error_validates_max_size) + " (#{(self.filesize.kilobytes / 1000).round} kB)")
        end
      end

      # Reverts the record to a previous version
      def revert_to!(version)
        if version.attachment_id == id
          update_columns(version.attributes.except("id").slice(*Attachment.column_names)) && reload
        end
      end

      def increment_download_with_easy_extensions
        #self.without_revision do
        increment_download_without_easy_extensions
        #end
      end

      protected

      def set_new_version
        self.version = next_version
      end

      private

      def next_version
        return 1 if new_record?
        (versions.maximum('version') || 0) + 1
      end

      def create_version
        versions << AttachmentVersion.new(attributes.except("id").slice(*AttachmentVersion.column_names))
      end

      def set_project_id_from_container
        self.project_id = container.try(:project_id)
      end

      def sanitize_filename_with_easy_extensions(value)
        @filename = self.class.sanitize_filename(value)
      end

    end

    module ClassMethods

      def visible_condition(user, options = {})
        return '1=1' if user.admin? || user.allowed_to_globally?(:view_easy_global_attachments)
        Project.allowed_to_condition(user, :view_easy_project_attachments, options)
      end

      def allowed_containers_for_query
        %w(Document Issue News)
      end

      def easy_activity_custom_project_scope(scope, options, event_type)
        scope.where(
            "CASE #{Attachment.table_name}.container_type
            WHEN 'Issue' THEN EXISTS(SELECT i.id FROM #{Issue.table_name} i WHERE i.id = #{Attachment.table_name}.container_id AND i.project_id in (?))
            WHEN 'Document' THEN EXISTS(SELECT d.id FROM #{Document.table_name} d WHERE d.id = #{Attachment.table_name}.container_id AND d.project_id in (?))
           END", options[:project_ids], options[:project_ids])
      end

      def update_digests_to_sha256_with_easy_extensions
        update_digests_to_sha256_without_easy_extensions
        AttachmentVersion.update_digests_to_sha256
      end

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Attachment', 'EasyPatch::AttachmentPatch'
#EasyExtensions::PatchManager.register_model_patch 'AttachmentVersion', 'EasyPatch::AttachmentVersionPatch'
