class EasyPageModulesController < ApplicationController
  layout 'admin'

  before_action :require_admin

  def used_modules
    @modules = EasyPageModule.preload([{ :available_in_pages => [:page_definition, :all_modules] }]).to_a.sort_by(&:translated_name)
  end

end
