require 'redmine/plugin'
module Redmine
  class Plugin

    def self.load
      directory = File.join(self.directory, 'easyproject')
      if File.directory?(directory)
        lib = File.join(directory, 'lib')
        if File.directory?(lib)
          $:.unshift lib
          ActiveSupport::Dependencies.autoload_paths += [lib]
        end
        initializer = File.join(directory, 'init.rb')
        if File.file?(initializer)
          require initializer
        end
        if Rails.env.test?
          require 'simplecov'

          SimpleCov.start do
            add_filter %r{^/app}
            add_filter %r{^/config}
            add_filter %r{^/lib}
            add_filter %r{^/plugins/easysoftware}
            add_filter %r{^/plugins/easyproject/easy_helpers}
            Redmine::Plugin.all.each do |plugin|
              next if File.dirname(plugin.directory).end_with? "easy_helpers"

              relative_dir = plugin.directory.sub(SimpleCov.root, "")
              add_group plugin.id.to_s, relative_dir
              add_filter %r{^#{relative_dir}/test}
            end
          end
        end
      end
    end
  end

end
