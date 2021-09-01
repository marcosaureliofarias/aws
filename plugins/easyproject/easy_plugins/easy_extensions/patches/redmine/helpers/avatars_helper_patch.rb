module EasyPatch
  module AvatarsHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :avatar, :easy_extensions

        def get_easy_absolute_uri_for(relative_uri = nil)
          relative_uri_with_prefix = [Rails.application.config.action_controller.relative_url_root, relative_uri].compact.join('/')
          if respond_to?(:request) && !request.nil?
            URI.join(request.base_url, relative_uri_with_prefix)
          else
            URI.join("#{Setting.protocol}://#{Setting.host_name}", relative_uri_with_prefix)
          end
        end
        
        def letter_avatar_url_for(entity, size = nil)
          size ||= 64
          if entity.respond_to?(:letter_avatar_path)
            get_easy_absolute_uri_for(LetterAvatar.path_to_url(entity.letter_avatar_path(size))).to_s
          end
        rescue
        end

        def letter_avatar_url_image_tag(entity, options = {})
          avatar_path = letter_avatar_url_for(entity, (options[:size]))
          avatar_path ? image_tag(avatar_path, options) : nil
        end

        def avatar_url(user = nil)
          user ||= User.current
          result = if Setting.gravatar_enabled?
                     options = { ssl: (request&.ssl?), default: Setting.gravatar_default }
                     email = nil
                     if user.respond_to?(:mail)
                       email = user.mail
                     elsif user.to_s =~ %r{<(.+?)>}
                       email = $1
                     end
                     email ? gravatar_url(email, options) : ''
                   elsif user.respond_to?(:easy_avatar) && (av = user.easy_avatar).present? && (img_url = av.image.url(:small))
                     get_easy_absolute_uri_for(img_url).to_s
                   elsif user.easy_avatar_url.present?
                     user.easy_avatar_url
                   else
                     letter_avatar_url_for(user)
                   end
          result
        end
      end
    end

    module InstanceMethods
      def avatar_with_easy_extensions(entity, options = {}, &block)
        return '' unless EasySetting.value('avatar_enabled')
        no_link = options.delete(:no_link)
        @easy_extensions_avatar_class = EasyExtensions::Avatar.new entity, self, options

        if block_given?
          img_tag = capture(@easy_extensions_avatar_class, &block).strip.html_safe
        else
          img_tag = @easy_extensions_avatar_class.to_html
        end
        wrapper_css = ['avatar-container']

        if entity.is_a?(User) && EasyExtensions::EasyProjectSettings.enable_action_cable
          case entity.easy_online_status
          when 'online'
            wrapper_css << 'status--on'
          when 'away'
            wrapper_css << 'status--away'
          when 'dnd'
            wrapper_css << 'status--dnd'
          end
        end

        if no_link || !entity.is_a?(User)
          if entity.nil?
            #unassigned
            '&nbsp;'.html_safe
          else
            content_tag('span', img_tag, class: wrapper_css.join(' '))
          end
        elsif entity.is_a?(User)
          content_tag('span', link_to(img_tag.to_s, profile_user_path(entity), remote: true, title: l(:title_user_profile, username: entity.name)), class: wrapper_css.join(' '))
        end
      end

    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'AvatarsHelper', 'EasyPatch::AvatarsHelperPatch'
