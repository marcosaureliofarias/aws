require 'rubygems'

require 'test/unit'
require 'active_support'

ENV["RAILS_ENV"] = "test"
require 'action_pack'
require 'action_controller'
require File.expand_path('../../lib/before_render', __FILE__)
