class EasyAvatarsController < ApplicationController

  before_action :find_entity

  def create
    class_param  = @entity.class.name.underscore.to_sym
    avatar_image = params[class_param][:easy_avatar] if params[class_param].present?
    if avatar_image.present?
      a = EasyAvatar.new(entity: @entity, image: avatar_image)
      a.valid?
      if a.errors[:image].blank?
        @entity.easy_avatar = a
        redirect_to({ :action => 'crop_avatar', :entity_id => @entity.id, :entity_type => @entity.class.name, :back_url => params[:back_url] })
      else
        flash[:error] = I18n.t(:message_avatar_error)
        redirect_to :back
      end
    else
      redirect_to :back
    end
  end

  def destroy
    @entity.easy_avatar.try(:destroy)
    respond_to do |format|
      format.js
      format.html { redirect_to :back }
    end
  end

  def crop_avatar
    if EasyExtensions::ImageProcessing.avaliable_ip_adapters.any?
      respond_to do |format|
        format.html
      end
    else
      flash[:warning] = l(:warning_without_imagemagick) unless EasySetting.value('hide_imagemagick_warning')
      redirect_to :back
    end
  end

  def save_avatar_crop
    if a = @entity.easy_avatar
      a.crop_x      = params[:crop_x]
      a.crop_y      = params[:crop_y]
      a.crop_width  = params[:crop_width]
      a.crop_height = params[:crop_height]
      if a.cropping?
        flash[:notice] = l(:message_avatar_uploaded)
        a.reprocess_original
        a.disable_cropping
        a.reprocess_thumbnails
      end
    end
    redirect_back_or_default({ :controller => 'my', :action => 'account' })
  end

  private

  def find_entity
    if params[:entity_id] && params[:entity_type]
      @entity = params[:entity_type].classify.constantize.find(params[:entity_id])
    elsif params[:id]
      # Old way only for users
      @entity = User.find(params[:id])
    else
      # Old default
      @entity = User.current
    end
  rescue ActiveRecord::RecordNotFound, NameError
    render_404
  end

end
