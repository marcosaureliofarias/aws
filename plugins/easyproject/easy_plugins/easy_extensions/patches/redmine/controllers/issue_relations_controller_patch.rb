module EasyPatch
  module IssueRelationsControllerPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do

        skip_before_action :find_issue, :authorize, :find_relation

        before_action :find_issue, :authorize, :only => [:index, :create]
        before_action :find_relation, :except => [:index, :create]

        helper :issues
        include IssuesHelper

        alias_method_chain :create, :easy_extensions
        alias_method_chain :destroy, :easy_extensions

        def unsaved_relations_errors(unsaved_relations, no_html = false)
          return nil if unsaved_relations.empty?
          separator = no_html ? "\n" : '<br>'

          unsaved_relations.map { |relation|
            errors = relation.errors.full_messages.join(separator)
            errors << relation.issue_from.errors.full_messages.map { |m| (no_html ? relation.issue_from.to_s : view_context.link_to_issue(relation.issue_from)) + ': ' + m }.join(separator) if relation.issue_from
            errors << relation.issue_to.errors.full_messages.map { |m| (no_html ? relation.issue_to.to_s : view_context.link_to_issue(relation.issue_to)) + ': ' + m }.join(separator) if relation.issue_to
            errors
          }.join(separator).html_safe
        end

      end
    end

    module InstanceMethods

      def create_with_easy_extensions
        @relation                 = IssueRelation.new
        @relation.issue_from      = @issue
        @relation.safe_attributes = params[:relation]

        unsaved_relations = []
        saved_relations   = []
        issues_to_id      = params[:relation] ? Array(params[:relation][:issue_to_id]).reject(&:blank?) : []
        if !issues_to_id.empty?
          issues_to_id.each do |issue_id|
            new_relation             = @relation.dup
            new_relation.issue_to_id = issue_id

            new_relation.init_journals(User.current)
            begin
              saved = new_relation.save
              saved_relations << new_relation
            rescue ActiveRecord::RecordNotUnique
              saved = false
              new_relation.errors.add :base, :taken
            end
            unsaved_relations << new_relation unless saved
          end
        else
          @relation.init_journals(User.current)
          begin
            saved = @relation.save
            saved_relations << @relation
          rescue ActiveRecord::RecordNotUnique
            saved = false
            @relation.errors.add :base, :taken
          end

          unsaved_relations << @relation unless saved
        end

        respond_to do |format|
          format.html do
            @unsaved_errors = unsaved_relations_errors(unsaved_relations)
            if @unsaved_errors
              flash[:error] = @unsaved_errors
            else
              flash[:notice] = l(:notice_successful_update)
            end
            redirect_to issue_path(@issue)
          end
          format.js {
            @relations      = @issue.reload.relations.select { |r| r.other_issue(@issue) && r.other_issue(@issue).visible? }
            @unsaved_errors = unsaved_relations_errors(unsaved_relations)
          }
          format.api {
            @unsaved_errors = unsaved_relations_errors(unsaved_relations, true)
            if @unsaved_errors
              render_api_errors(@unsaved_errors)
            else
              if saved_relations.one?
                render action: 'show', status: :created, location: relation_url(saved_relations.first)
              else
                head :created
              end
            end
          }
        end

      end

      def destroy_with_easy_extensions
        raise Unauthorized unless @relation.deletable?
        @relation.init_journals(User.current)
        @relation.destroy

        respond_to do |format|
          format.html {
            if params[:issue_id].present?
              redirect_to issue_path(params[:issue_id])
            else
              redirect_to issue_path(@relation.issue_from)
            end
          }
          format.js
          format.api { render_api_ok }
        end
      end

    end
  end

end
EasyExtensions::PatchManager.register_controller_patch 'IssueRelationsController', 'EasyPatch::IssueRelationsControllerPatch'
