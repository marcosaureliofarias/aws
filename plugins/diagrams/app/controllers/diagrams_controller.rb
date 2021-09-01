class DiagramsController < ApplicationController
  menu_item :diagrams

  helper :easy_page_modules
  helper :context_menus
  include EasyPageModulesHelper
  include_query_helpers

  skip_before_action :verify_authenticity_token

  before_action :authorize_global
  before_action :load_diagram, only: [:show, :export, :save, :destroy, :toggle_position]
  before_action :load_diagrams, only: [:context_menu, :bulk_destroy]
  before_action :load_back_url, only: [:show, :save, :destroy, :bulk_destroy]

  def index
    index_for_easy_query(DiagramQuery)
  end

  def show; end

  def save
    @diagram.update(xml_png: Addressable::URI.unescape(params[:xmlpng]))
    @diagram.create_version!

    if @back_url.present?
      flash[:notice] = l('diagrams.diagram_saved')

      render json: {}, status: 200, location: @back_url
    else
      head :no_content
    end
  end

  def destroy
    @diagram.destroy

    flash[:notice] = l('diagrams.diagram_deleted')
    redirect_back_or_default(diagrams_path)
  end

  def bulk_destroy
    @diagrams.destroy_all

    flash[:notice] = l('diagrams.diagrams_deleted')
    redirect_back_or_default(diagrams_path)
  end

  def toggle_position
    @diagram.update(current_position: params[:position])

    redirect_back_or_default(diagrams_path)
  end

  def generate
    @diagram = Diagram.create(title: title_param)

    render json: {
      identifier: @diagram.identifier,
      path: diagram_path(@diagram)
    }
  end

  def context_menu
    @diagram = @diagrams.first if @diagrams.one?

    @can = { edit: true, delete: true }
    @back_url = back_url

    render layout: false
  end

  private

  def title_param
    params[:title].presence || l('diagrams.default_title')
  end

  def load_diagram
    @diagram = Diagram.find(params[:id])
  end

  def load_diagrams
    @diagrams = Diagram.where(id: params[:id] || params[:ids])
  end

  def load_back_url
    @back_url = params[:back_url]
  end
end
