class EasyTranslationsController < ApplicationController
  before_action :require_login

  before_action :find_entity, :except => [:destroy]
  before_action :cached_languages, :only => [:index, :create]

  def index
    @translations      = @entity.easy_translations.where(:entity_column => @entity_column)
    @available_locales = @translated_langs_from_cache.keys - @translations.pluck(:lang)

    respond_to do |format|
      format.js
    end
  end

  def update
    @easy_translations_attributes = params[:easy_translations]
    if @easy_translations_attributes
      ActiveRecord::Base.transaction do
        if @easy_translations_attributes[:original_value]
          @entity.write_attribute(@entity_column, @easy_translations_attributes[:original_value], :translated => false)
          raise ActiveRecord::Rollback unless @entity.valid?

          @entity.write_attribute(@entity_column, @easy_translations_attributes[:original_value], :locale => nil)
          raise ActiveRecord::Rollback unless @entity.save
        end
        @entity.easy_translations.each do |t|
          if @easy_translations_attributes[t.id.to_s]
            t.value = @easy_translations_attributes[t.id.to_s]
            raise ActiveRecord::Rollback unless t.save
          end
        end
      end
    end
    respond_to do |format|
      format.html { redirect_back_or_default(@entity) }
      format.js {
        invalid_entities = [@entity].concat(@entity.easy_translations).compact.select { |e| !e.valid? }
        @error_messages  = invalid_entities.map { |e| e.errors.full_messages }.join('<br>').html_safe if !invalid_entities.empty?
      }
    end
  end

  def create
    @easy_translation = @entity.easy_translations.create(:entity_column => @entity_column, :lang => params[:lang], :value => @entity.send(@entity_column))
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @easy_translation = EasyTranslation.find_by(:id => params[:id])
    @easy_translation.destroy if @easy_translation
    respond_to do |format|
      format.js
    end
  end

  private

  def find_entity
    @entity_class  = params[:entity_type].camelcase.constantize
    @entity        = @entity_class.find(params[:entity_id])
    @entity_column = @entity_class.translater_options[:columns].detect { |i| i.to_s == params[:entity_column] }
  rescue StandardError
    render_404
  end

  def cached_languages
    @translated_langs_from_cache = languages_options.inject({}) { |mem, var| mem[var.last.to_s] = var.first; mem }
  end
end
