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
