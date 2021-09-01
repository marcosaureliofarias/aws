module EasyPatch
  module NewsPatch

    def self.included(base)

      base.class_eval do

        html_fragment :description, scrub: :strip

        searchable_options[:additional_conditions] = "#{Project.table_name}.easy_is_easy_template = #{connection.quoted_false}"

        acts_as_user_readable

        safe_attributes 'spinned'

        include EasyExtensions::EasyInlineFragmentStripper
        strip_inline_images :description

        def to_s
          title
        end

        def editable?(user = User.current)
          user.admin? || user.allowed_to?(:manage_news, project) || (user.allowed_to?(:manage_own_news, project) && author == user)
        end

        def attachments_editable?(user = User.current)
          editable?(user)
        end

        def attachments_deletable?(user = User.current)
          editable?(user)
        end

        class << self

        end

      end
    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'News', 'EasyPatch::NewsPatch'
