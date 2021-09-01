module EasyExtensions
  class EasyAssets

    def self.easy_images_public_path
      'images'
    end

    def self.easy_images_public_root
      Rails.public_path.join(easy_images_public_path)
    end

    def self.easy_images_base(entity_class)
      hash        = {}
      hash[:path] = File.join(Attachment.storage_path, 'easy_images', entity_class.name.pluralize.underscore)
      hash[:url]  = '/' + File.join(easy_images_public_path, 'easy_images', entity_class.name.pluralize.underscore)
      hash
    end

    def self.easy_images_options(entity_class, options)
      hash        = easy_images_base(entity_class)
      hash[:path] += options
      hash[:url]  += options
      hash
    end

    def self.copy_to_public(entity)
      return unless entity.try(:id)
      return unless EasyExtensions::EasyProjectSettings.enable_copying_easy_images_to_public
      src      = File.join(self.easy_images_base(entity.class)[:path], entity.id.to_s)
      dst_base = easy_images_public_root.join('easy_images', entity.class.name.pluralize.underscore)
      dst      = File.join(dst_base, entity.id.to_s)
      if File.exists?(src)
        FileUtils.rm_rf(dst)
        FileUtils.mkdir_p(dst_base) unless File.exists? dst_base
        FileUtils.cp_r(src, dst_base)
      end
    end

    def self.remove_from_public(entity)
      return unless entity.try(:id)
      return unless EasyExtensions::EasyProjectSettings.enable_copying_easy_images_to_public
      dst = easy_images_public_root.join('easy_images', entity.class.name.pluralize.underscore, entity.id.to_s)
      FileUtils.rm_rf(dst)
    end

    def self.mirror_easy_images
      return unless EasyExtensions::EasyProjectSettings.enable_copying_easy_images_to_public
      src      = File.join(Attachment.storage_path, 'easy_images')
      dst_base = easy_images_public_root
      dst      = File.join(dst_base, 'easy_images')
      File.exists?(src) ? FileUtils.rm_rf(dst) : FileUtils.mkdir_p(src)
      FileUtils.cp_r(src, dst_base)
    end

    def self.mirror_assets(name = nil)
      if name.present?
        Redmine::Plugin.find(name).mirror_assets
      else
        begin
          if File.exist?(Redmine::Plugin.public_directory)
            FileUtils.rm_r(Redmine::Plugin.public_directory)
          end
          cached_css        = File.join(Rails.public_path, 'stylesheets', EasyExtensions::CACHE_CSS_NAME + '.css')
          cached_js         = File.join(Rails.public_path, 'javascripts', EasyExtensions::CACHE_JS_NAME + '.js')
          redmine_cached_js = File.join(Rails.public_path, 'javascripts', EasyExtensions::REDMINE_CACHE_JS_NAME + '.js')

          FileUtils.rm(cached_css) if File.exist?(cached_css)
          FileUtils.rm(cached_js) if File.exist?(cached_js)
          FileUtils.rm(redmine_cached_js) if File.exist?(redmine_cached_js)
        rescue StandardError => e
          puts "Could not delete plugin assets: " + e.message
        end
        Redmine::Plugin.all.each(&:mirror_assets)
      end
    end
  end
end
