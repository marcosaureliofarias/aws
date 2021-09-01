module EasyPatch
  module CustomValuePatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        include EasyExtensions::EasyInlineFragmentStripper
        strip_inline_images :value, if: proc { |cv| cv.value && cv.custom_field && (cv.custom_field.text_formatting == 'full' || ['string', 'text'].include?(cv.custom_field.field_format)) }
        html_fragment :value, scrub: :strip, if: proc { |cv| cv.custom_field && (cv.custom_field.text_formatting == 'full' || ['string', 'text'].include?(cv.custom_field.field_format)) }

        scope :enabled, lambda { |*args| includes(:custom_field).where('custom_fields.disabled = ?', false) }

        has_many :easy_custom_field_ratings

        acts_as_attachable

        before_save :custom_value_before_save
        after_save :custom_value_after_save

        def self.get_next_autoincrement(custom_field, customized)
          settings                             = custom_field.settings || {}
          autoincrement_from, autoincrement_to = settings['from'].to_i, settings['to'].to_i

          autoincrement_from                   = 1 if autoincrement_from <= 0
          autoincrement_to                     = 999 if autoincrement_to <= 0

          scope = CustomValue.joins(:custom_field).where(["#{CustomValue.table_name}.custom_field_id = ?", custom_field.id]).
              where(["#{CustomField.table_name}.type = ?", custom_field.type]).
              where(["CAST(CASE #{CustomValue.table_name}.value WHEN '' THEN '0' ELSE #{CustomValue.table_name}.value END AS decimal(60,0)) BETWEEN ? AND ?",
                     autoincrement_from, autoincrement_to])

          if custom_field.type == 'IssueCustomField' && (settings['per_project'] == '1' || settings['per_tracker'] == '1')
            scope = scope.joins("INNER JOIN #{Issue.table_name} ON #{Issue.table_name}.id = #{CustomValue.table_name}.customized_id").where.not(issues: { id: customized.id })
            if settings['per_project'] == '1'
              scope = scope.where(["#{Issue.table_name}.project_id = ?", customized.project_id])
            end
            if settings['per_tracker'] == '1'
              scope = scope.where(["#{Issue.table_name}.tracker_id = ?", customized.tracker_id])
            end
          end

          current_max = scope.maximum("CAST(#{CustomValue.table_name}.value as decimal)").to_i
          return autoincrement_from if current_max.zero?
          (current_max < autoincrement_to) ? current_max.next : autoincrement_from
        end

        def self.get_next_formatted_autoincrement(custom_field, customized)
          autoincrementnumber = get_next_autoincrement(custom_field, customized)
          format_autoincrement(custom_field, autoincrementnumber)
        end

        def self.format_autoincrement(custom_field, autoincrementnumber)
          max_length = custom_field.min_length || 0
          if custom_field.max_length && custom_field.max_length > max_length
            max_length = custom_field.max_length
          else
            max_length = 0
          end
          sprintf("%0#{max_length}d", autoincrementnumber)
        end

        # workaround link_to_attachments - vyzaduje metodu project
        def project
          nil
        end

        # This method already exists at CustomValue and its quite good
        # Other posiibility is using a `customized.visible_custom_field_values`
        #
        # Original method have reguired argument
        #
        def attachments_visible_with_easy_extensions?(user = User.current)
          attachments_visible_without_easy_extensions?(user)
        end

        alias_method_chain :attachments_visible?, :easy_extensions

        def attachments_editable?(user = User.current)
          if user.admin?
            return true
          end

          if !customized
            return false
          end

          if customized.respond_to?(:editable_custom_field_values)
            customized.editable_custom_field_values(user).any? do |editable_cv|
              editable_cv.custom_field.id == custom_field_id
            end
          elsif customized.respond_to?(:editable?)
            customized.editable?
          else
            false
          end
        end

        def attachments_deletable?(user = User.current)
          attachments_editable?(user)
        end

        def format
          self.custom_field.field_format
        end

        def cast_value(cf = nil)
          cf ||= self.custom_field
          cf.cast_value(self.value)
        end

        def user_already_rated?
          if custom_field.field_format == 'easy_rating' && User.current
            easy_custom_field_ratings.where(:user_id => User.current.id).exists?
          else
            false
          end
        end

        private

        def attach_stripped_image(filename, file, extension)
          customized.attachments.create(
              :file         => file,
              :filename     => filename,
              :author       => User.current,
              :description  => !!EasySetting.value('attachment_description_required') && '*' || '',
              :content_type => "image/#{extension}") if customized.respond_to?(:attachments) && customized.attachments.respond_to?(:create)
        end

        def custom_value_after_save
          self.custom_field.format.custom_value_after_save(self)
          true
        end

        def custom_value_before_save
          self.custom_field.format.custom_value_before_save(self)
          true
        end

      end
    end

    module InstanceMethods

    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'CustomValue', 'EasyPatch::CustomValuePatch'
