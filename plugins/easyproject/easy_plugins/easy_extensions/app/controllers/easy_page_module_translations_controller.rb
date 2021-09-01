class EasyPageModuleTranslationsController < ApplicationController
  before_action :require_login
  before_action :find_page_module

  def index
    page_module_params = params[@page_module.module_name].to_unsafe_hash
    @keys              = params[:keys]
    @translations      = page_module_params.dig('translations', *@keys) || {}
    @original_value    = page_module_params.dig(*@keys)

    @translated_langs_from_cache = languages_options.each_with_object({}) { |var, mem| mem[var.last.to_s] = var.first }
    @available_locales           = @translated_langs_from_cache.keys - @translations.keys
  end

  def add
    @translation = { params[:locale] => nil }
    @input_name  = params[:input_name]
  end

  private

  def find_page_module
    if [EasyPageTemplateModule.to_s, EasyPageZoneModule.to_s].include?(params[:module_class])
      klass        = params[:module_class].constantize
      @page_module = klass.find_by(uuid: params[:uuid])
    else
      render_404
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
