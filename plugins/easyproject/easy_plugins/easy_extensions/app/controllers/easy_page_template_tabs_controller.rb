class EasyPageTemplateTabsController < ApplicationController

  before_action :find_template

  private

  # entity_id should always be nil but just in case :-)
  def find_template
    if params[:id].present?
      @tab       = EasyPageTemplateTab.preload(:page_template_definition).find(params[:id])
      @template  = @tab.page_template_definition
      @entity_id = nil
    elsif params[:template_id].present?
      @tab       = nil
      @template  = EasyPageTemplate.find(params[:template_id])
      @entity_id = nil
    end

    return render_404 if @template.nil?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
