require 'easy_extensions/spec_helper'

describe 'reloader' do
  class MockConsole
    require "rails/console/app"

    include Rails::ConsoleMethods
  end

  it 'reload!', skip: ENV['TAGS'] != 'reloader', reloader: true do
    expect { MockConsole.new.reload! }.not_to raise_exception
  end
end
