desc 'Generates initializers'

namespace :easyproject do

  task :patch_initializers do
    path = File.join(Rails.root, 'config', 'boot.rb')
    File.open(path, 'w') do |f|
      f.write <<"EOF"
# frozen_string_literal: true

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

unless ENV['DISABLE_BOOTSNAP']
  begin
    require "bootsnap/setup"
    puts 'Start with bootsnap'
  rescue LoadError
    nil
  end
end
EOF
    end
    path = File.join(Rails.root, 'config', 'initializers', '22-change_plugins_order.rb')
    File.open(path, 'w') do |f|
      f.write <<"EOF"
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
              add_filter %r{^\#{relative_dir}/test}
            end
          end
        end
      end
    end
  end

end
EOF
    end

    path = File.join(Rails.root, 'config', 'initializers', '30-redmine.rb')
    File.open(path, 'w') do |f|
      f.write <<"EOF"
# frozen_string_literal: true

I18n.backend = Redmine::I18n::Backend.new
# Forces I18n to load available locales from the backend
I18n.config.available_locales = nil

require 'redmine'

# Load the secret token from the Redmine configuration file
secret = Redmine::Configuration['secret_token']
if secret.present?
  RedmineApp::Application.config.secret_token = secret
end

if Object.const_defined?(:OpenIdAuthentication)
  openid_authentication_store = Redmine::Configuration['openid_authentication_store']
  OpenIdAuthentication.store = openid_authentication_store.presence || :memory
end

Redmine::Plugin.load

# disable assets reloader
unless Redmine::Configuration['mirror_plugins_assets_on_startup'] == false
  Redmine::Plugin.mirror_assets
end

Rails.application.config.to_prepare do
  Redmine::FieldFormat::RecordList.subclasses.each do |klass|
    klass.instance.reset_target_class
  end
end

EOF
    end
  end

end
