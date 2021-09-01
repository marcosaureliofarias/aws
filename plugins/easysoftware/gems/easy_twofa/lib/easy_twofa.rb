# This engine is inspired by https://www.redmine.org/issues/1237
# However the patches will be included after very long time or
# not at all.

require 'rys'
require 'easy_twofa/version'
require 'easy_twofa/engine'

module EasyTwofa

  configure do |c|
    c.remember_for = 14 # in days
    c.max_attempts = 3
  end

  def self.easy_extensions?
    @easy_extensions ||= Redmine::Plugin.installed?(:easy_extensions)
  end

end
