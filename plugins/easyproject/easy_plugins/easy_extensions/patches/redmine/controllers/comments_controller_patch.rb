module EasyPatch
  module CommentsControllerPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do

        # skip_before_action :authorize
        # before_action :authorize_global

        accept_api_auth :create, :destroy

        alias_method_chain :find_model_object, :easy_extensions
        alias_method_chain :destroy, :easy_extensions
        alias_method_chain :create, :easy_extensions

        def new
          @comment = @object.comments.build
          respond_to do |format|
            format.js # new.js.erb
          end
        end

        def authorize
          return render_403 if !@object.commentable?
        end

      end
    end

    module InstanceMethods

      def create_with_easy_extensions
        raise Unauthorized unless @object.commentable?

        @comment                 = @object.comments.build
        @comment.safe_attributes = params[:comment]
        @comment.author          = User.current

        if @object.respond_to?(:user_read_records)
          @object.user_read_records.where.not(user_id: User.current.id).destroy_all
        end

        respond_to do |format|
          if @comment.save
            if @object.respond_to?(:mark_as_read)
              @object.mark_as_read
            end
            format.html { redirect_to(polymorphic_path(@object), :notice => l(:label_comment_added)) }
            format.json { render :json => @comment, :status => :created, :location => polymorphic_url(@object) }
            format.xml { render :xml => @comment, :status => :created, :location => polymorphic_url(@object) }
          else
            format.api { render_validation_errors(@comment) }
          end
          format.js # create.js.erb
        end
      end

      def destroy_with_easy_extensions
        @comments = @object.comments
        @comments = @comments.where(:author_id => User.current.id) if !User.current.allowed_to_globally?(:manage_comments, {}) && User.current.allowed_to_globally?(:delete_own_comments, {})
        @comment  = @comments.find(params[:comment_id])
        @comment && @comment.destroy
        respond_to do |format|
          format.html { redirect_back_or_default polymorphic_path(@object) }
          format.js # destroy.js.erb
          format.api { render_api_ok }
        end
      end

      def find_model_object_with_easy_extensions
        if params[:entity_type].present? && params[:entity_id]
          @object = params[:entity_type].classify.constantize.find(params[:entity_id])
        else
          return render_404
        end
        #find_model_object_without_easy_extensions
      end

    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'CommentsController', 'EasyPatch::CommentsControllerPatch'
