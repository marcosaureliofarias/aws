module EasyPatch
  module JournalsControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        helper :easy_query
        include EasyQueryHelper

        # cache_sweeper :journal_sweeper, :only => [:edit]

        skip_before_action :find_issue, :authorize, only: [:new]
        before_action :find_entity, :authorize, only: [:new]
        before_action :find_journalized, only: :load_journals

        alias_method_chain :find_journal, :easy_extensions
        alias_method_chain :edit, :easy_extensions
        alias_method_chain :index, :easy_extensions
        alias_method_chain :new, :easy_extensions
        alias_method_chain :diff, :easy_extensions
        alias_method_chain :update, :easy_extensions


        def public_journal
          @journal = Journal.visible.find(params[:id])
          if @journal.user_id == User.current.id || User.current.admin?
            @journal.update_attributes(:private_notes => false)
            flash[:notice] = l(:notice_journal_published)
            redirect_to @journal.journalized
          else
            render_403
          end
        end

        def load_journals
          reversed_comments = User.current.wants_comments_in_reverse_order?

          @journals = @entity.journals.where(:easy_type => nil).
              preload([{ :user => (Setting.gravatar_enabled? ? :email_address : :easy_avatar) }, :details]).
              reorder(created_on: (reversed_comments ? :desc : :asc))

          @journals = @journals.where(private_notes: false) unless User.current.allowed_to?(:view_private_notes, @entity.respond_to?(:project) && @entity.project)

          @journals = @journals.to_a
          return render_404 if @journals.empty?
          Journal.preload_journals_details_custom_fields(@journals)
          @journals.select! { |journal| journal.notes? || journal.visible_details.any? }

          respond_to do |format|
            format.js
          end
        end

        private

        def find_journalized
          journalized_type = params[:journalized_type]&.safe_constantize
          return render_404 unless journalized_type
          @entity = journalized_type.find(params[:journalized_id])
        rescue ActiveRecord::RecordNotFound
          render_404
        end

        def find_entity
          if params[:journal_id]
            @journal = Journal.find(params[:journal_id])
            @project = @journal.journalized.try(:project) if @journal.journalized.respond_to?(:project)
          elsif params[:id]
            find_issue
          end
        rescue ActiveRecord::RecordNotFound
          render_404
        end

      end
    end

    module InstanceMethods

      def find_journal_with_easy_extensions
        @journal = Journal.find(params[:id]) # original s visible je primo svazan s issue
        @project = @journal.journalized.try(:project) if @journal && @journal.journalized.respond_to?(:project)
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def index_with_easy_extensions
        retrieve_query(EasyIssueQuery)

        if @query.valid?
          @journals = @query.journals(:order => "#{Journal.table_name}.created_on DESC",
                                      :limit => 25)
        end
        @title = (@project ? @project.name : Setting.app_title) + ": " + (@query.new_record? ? l(:label_changes_details) : @query.name)
        render :layout => false, :content_type => 'application/atom+xml'
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def new_with_easy_extensions
        if @journal
          user = @journal.user
          text = @journal.notes
        elsif @issue
          user = @issue.author
          text = @issue.description
        end
        # Replaces pre blocks with [...]
        text     = text.to_s.strip.gsub(%r{<pre>(.*?)</pre>}m, '[...]')
        @content = "#{ll(Setting.default_language, :text_user_wrote, user)}\n> "
        # If CKEDITOR else redmine default
        if Setting.text_formatting == 'HTML'
          @content << content_tag(:blockquote, text.html_safe) + "\n\n"
        else
          @content << text.gsub(/(\r?\n|\r\n?)/, "\n> ") + "\n\n"
        end
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def edit_with_easy_extensions
        (render_403; return false) unless @journal.editable_by?(User.current)
        if request.post?
          @journal.update_attributes(:notes => params[:notes]) if params[:notes]
          @journal.destroy if @journal.details.empty? && @journal.notes.blank?
          call_hook(:controller_journals_edit_post, { :journal => @journal, :params => params })
          respond_to do |format|
            format.html { redirect_back_or_default({ :controller => @journal.journalized.class.name.underscore.pluralize, :action => 'show', :id => @journal.journalized, :project_id => @project }) }
            format.js { render :action => 'update' }
          end
        else
          respond_to do |format|
            # TODO: implement non-JS journal update
            format.js
          end
        end
      end

      def update_with_easy_extensions
        (render_403; return false) unless @journal.editable_by?(User.current)
        @journal.safe_attributes = params[:journal]
        @journal.save
        @journal.destroy if @journal.details.empty? && @journal.notes.blank?
        call_hook(:controller_journals_edit_post, { :journal => @journal, :params => params })
        respond_to do |format|
          format.html { redirect_to issue_path(@journal.journalized) }
          format.js
          format.api { render request.format.symbol => @journal }
        end
      end

      def diff_with_easy_extensions
        @issue  = @journal.issue if @journal.journalized_type == 'Issue'
        @entity = @journal.journalized
        if params[:detail_id].present?
          @detail = @journal.details.find_by(id: params[:detail_id])
        else
          @detail = @journal.details.detect { |d| d.property == 'attr' && d.prop_key == 'description' }
        end
        unless @detail
          render_404
          return false
        end

        if @entity.respond_to?(:visible?) && !@entity.visible?
          raise ::Unauthorized
        end

        if @detail.property == 'cf' && @entity.respond_to?(:project)
          unless @detail.custom_field && @detail.custom_field.visible_by?(@entity.project, User.current)
            raise ::Unauthorized
          end
        end
        @diff = Redmine::Helpers::Diff.new(@detail.value, @detail.old_value)
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'JournalsController', 'EasyPatch::JournalsControllerPatch'
