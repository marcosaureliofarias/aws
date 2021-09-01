module Easy
  module Redmine
    class BasicController < ApplicationController

      class_attribute :entity_class
      class_attribute :entity_query_class
      class_attribute :allow_custom_type

      before_action -> { check_entity_class }
      before_action -> { find_parent_entity }
      before_action -> { runtime_entity_class }, only: %i[index new create]
      before_action -> { find_entity }, only: %i[show edit update destroy]
      before_action -> { find_copy_from }, only: %i[new create]
      before_action -> { new_entity }, only: %i[index new create]
      before_action -> { assign_attributes }, only: %i[new create edit update]

      helper :journals, :context_menus, :issues, :custom_fields
      include JournalsHelper
      helper :easy_journal
      include CustomFieldsHelper

      include_query_helpers

      def index
        index_for_easy_query(entity_query_class) if entity_query_class
      end

      def new
        respond_to do |format|
          format.html
          format.js
        end
      end

      def create
        if @entity.save
          respond_to do |format|
            format.html {
              flash[:notice] = l(:notice_successful_create)
              redirect_back_or_default polymorphic_path(@entity.to_route)
            }
            format.js
          end
        else
          respond_to do |format|
            format.html { render action: 'new' }
            format.js
          end
        end
      end

      def show
      end

      def edit
        respond_to do |format|
          format.html
          format.js
        end
      end

      def update
        if @entity.save
          respond_to do |format|
            format.html {
              flash[:notice] = l(:notice_successful_update)
              redirect_back_or_default polymorphic_path(@entity.to_route)
            }
            format.js
          end
        else
          respond_to do |format|
            format.html { render action: 'edit' }
            format.js
          end
        end
      end

      def destroy
        @entity.destroy

        respond_to do |format|
          format.html {
            flash[:notice] = l(:notice_successful_delete)
            redirect_back_or_default polymorphic_path(entity_class.to_route(@parent_entity))
          }
          format.js
        end
      end

      protected

      def check_entity_class
        raise StandardError.new('You have to specify entity class attribute!') if self.entity_class.nil?
      end

      def entity_class_scope
        self.entity_class.all
      end

      def runtime_entity_class
        return @runtime_entity_class if @runtime_entity_class

        @runtime_entity_class =
            if allow_custom_type && self.entity_class.allowed_subclass?(params[:type], User.current)
              params[:type].safe_constantize
            else
              self.entity_class
            end

        @runtime_entity_class.presence || render_404
      rescue NameError
        render_404
      end

      def params_entity_symbol
        runtime_entity_class.base_class.model_name.param_key
      end

      def find_entity
        @entity               = klass_find(entity_class_scope, params[:id])
        @parent_entity        = @entity.parent_entity
        @runtime_entity_class = @entity.class
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def find_parent_entity
        @parent_entity = klass_find(self.entity_class.parent_entity_class, params[self.entity_class.parent_entity_id_symbol]) if self.entity_class.parent_entity_class && params[self.entity_class.parent_entity_id_symbol]
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def find_copy_from
        @copy_from = klass_find(runtime_entity_class, params[:copy_from]) if params[:copy_from]
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def new_entity
        #@entity               = runtime_entity_class.copy_from(@copy_from) if @copy_from
        @entity               = runtime_entity_class.new
        @entity.parent_entity = @parent_entity
      end

      def assign_attributes
        @entity.parent_entity   ||= @parent_entity if @parent_entity
        @entity.author          = User.current if @entity.respond_to?(:author_id) && @entity.new_record?
        @entity.updated_by      = User.current if @entity.respond_to?(:updated_by_id) && !@entity.new_record?
        @entity.safe_attributes = params[params_entity_symbol] if params[params_entity_symbol]
      end

      def klass_find(klass, ident)
        klass.respond_to?(:friendly) ? klass.friendly.find(ident) : klass.find(ident)
      end
    end

  end
end
