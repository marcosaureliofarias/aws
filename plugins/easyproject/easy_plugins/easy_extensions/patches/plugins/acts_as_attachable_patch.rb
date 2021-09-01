module EasyPatch
  module ActsAsAttachableInstancePatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :save_attachments, :easy_extensions

        # Find an attachment that could be versioned
        def get_existing_version(file_filename, attachment)
          if attachment['custom_version_for_attachment_id'].present?
            Attachment.find(attachment['custom_version_for_attachment_id'])
          else
            (self.attachments + saved_attachments).detect { |i| i.filename == Attachment.sanitize_filename(file_filename) && (attachment['category'] ? attachment['category'] == i.category : true) }
          end
        end

        def after_new_version_create_journal(attachment)
          if self.respond_to?(:current_journal) && !self.current_journal.nil?
            if (lastest_version = attachment.versions.latest)
              self.current_journal.details << JournalDetail.new(:property => 'attachment_version', :prop_key => lastest_version.id, :value => lastest_version.filename)
            end
          end
        end

        def validate_attachment
          if unsaved_attachments.any?
            self.errors.add(:base, unsaved_attachments.first.errors.full_messages.join(', '))
          end
        end

        def attachments_editable?(user = User.current)
          (respond_to?(:visible?) ? visible?(user) : true) &&
              user.allowed_to?(self.class.attachable_options[:edit_permission], self.project)
        end

        def attachments_delegable?
          false
        end

      end
    end

    module InstanceMethods

      def attachments_fill_project_id
        attachments.each do |atttachment|
          atttachment.update_column(:project_id, project_id)
          atttachment.versions.update_all(project_id: project_id)
        end
      end

      def save_attachments_with_easy_extensions(attachments, author = User.current)
        attachments  = attachments.to_unsafe_hash if attachments.respond_to?(:to_unsafe_hash)
        new_versions = Array.new
        if attachments.is_a?(Hash)
          attachments = attachments.stringify_keys
          attachments = attachments.to_a.sort { |a, b|
            if a.first.to_i > 0 && b.first.to_i > 0
              a.first.to_i <=> b.first.to_i
            elsif a.first.to_i > 0
              1
            elsif b.first.to_i > 0
              -1
            else
              a.first <=> b.first
            end
          }
          attachments = attachments.map(&:last)
        end
        if attachments.is_a?(Array)
          @failed_attachment_count = 0
          attachments.each do |attachment|
            attachment = attachment.to_unsafe_hash if attachment.respond_to?(:to_unsafe_hash)
            next unless attachment.is_a?(Hash)
            a = nil
            if (file = attachment['file'])
              next unless file.respond_to?(:original_filename)
              select_attachment = get_existing_version(file.original_filename, attachment)
              if select_attachment
                select_attachment.attributes = {
                    :file        => file,
                    :description => attachment['description'].to_s.strip,
                    :container   => self,
                    :author      => author }
                select_attachment.files_to_final_location
                select_attachment.save

                after_new_version_create_journal(select_attachment)
                new_versions << select_attachment
              else
                a = Attachment.create(:file => file, :author => author, :description => attachment['description'].to_s.strip)
              end
            elsif (token = attachment['token'])
              a = Attachment.find_by_token(token)
              unless a
                @failed_attachment_count += 1
                next
              end
              a.filename     = attachment['filename'] unless attachment['filename'].blank?
              a.content_type = attachment['content_type'] unless attachment['content_type'].blank?
              a.description  = attachment['description'].to_s.strip unless attachment['description'].blank?
              # Assign new attachment to self
              a.container           = self
              a.custom_field_values = attachment['custom_field_values'] if attachment['custom_field_values'].present?
              select_attachment     = get_existing_version(a.filename, attachment)

              # new version?
              if select_attachment && a.valid?
                # Update existing attachment - create new version
                a_attributes = a.attributes.dup
                a_attributes.delete('id'); a_attributes.delete('version')
                if (cfv = attachment['custom_field_values'])
                  a_attributes['custom_field_values'] = cfv
                end

                select_attachment.update_attributes(a_attributes)
                new_versions << select_attachment

                # Create journalDetail if possible
                after_new_version_create_journal(select_attachment)

                # delete unused attachment - this attachment is in new version
                a.delete
                a = nil
              end
            end

            next unless a
            if a.new_record? || !a.valid?
              unsaved_attachments << a
            else
              saved_attachments << a
            end
          end
        end
        { :files => saved_attachments, :unsaved => unsaved_attachments, :new_versions => new_versions }
      end

      def has_attachments?
        attachments.any?
      end

    end

  end


  module ActsAsAttachableClassPatch

    def self.included(base)
      base.include(ClassMethods)

      base.class_eval do

        alias_method_chain :acts_as_attachable, :easy_extensions

      end
    end

    module ClassMethods

      def acts_as_attachable_with_easy_extensions(options = {})
        cattr_accessor :attachable_options
        self.attachable_options                = {}
        attachable_options[:view_permission]   = options.delete(:view_permission) || "view_#{self.name.pluralize.underscore}".to_sym
        attachable_options[:edit_permission]   = options.delete(:edit_permission) || "edit_#{self.name.pluralize.underscore}".to_sym
        attachable_options[:delete_permission] = options.delete(:delete_permission) || "edit_#{self.name.pluralize.underscore}".to_sym

        has_many :attachments, lambda { order("#{Attachment.table_name}.created_on DESC, #{Attachment.table_name}.id DESC") },
                 options.merge(:as => :container, :dependent => :destroy, :inverse_of => :container)

        validate :validate_attachment

        send :include, Redmine::Acts::Attachable::InstanceMethods
        before_save :attach_saved_attachments
        after_save :attachments_fill_project_id, if: proc { |p| p.respond_to?(:project_id) && p.try(:saved_change_to_project_id?) }
        validate :warn_about_failed_attachments
      end
    end

  end
end
EasyExtensions::PatchManager.register_patch_to_be_first 'Redmine::Acts::Attachable::InstanceMethods', 'EasyPatch::ActsAsAttachableInstancePatch', :first => true
EasyExtensions::PatchManager.register_patch_to_be_first 'Redmine::Acts::Attachable::ClassMethods', 'EasyPatch::ActsAsAttachableClassPatch', :first => true
