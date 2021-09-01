class EasyContactsSettingsController < CustomFieldsController

  helper :easy_setting

  before_action :find_contact_type, only: [:contact_type_move]
  before_action :find_field, only: [:edit_field, :update_field]
  before_action :prepare_contact_types, only: [:index]

  include ProjectsHelper

  def edit_field
    @easy_settings = EasySettings::FormModel.new

    respond_to do |format|
      format.html
    end
  end

  def update_field
    save_easy_settings
    redirect_back_or_default easy_contacts_settings_path(tab: 'EasyContactFieldsSettings')
  end

  def contact_type_move
    @contact_type.update_attributes(params[:easy_contact_type])
    redirect_to(action: 'index', tab: 'EasyContactType')
  end
  
  private

  def find_field
    render_404 unless EasyContact.column_names.include?(params[:field_id])
  end

  def find_contact_type
    @contact_type = EasyContactType.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def prepare_contact_types
    @types = EasyContactType.sorted
  end

end