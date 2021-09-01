module RedmineRe
  module MailerPatch
    def self.included(base)
      base.include InstanceMethods
    end


    module InstanceMethods
      def deliver_artifact_add(artifact)
        users = artifact.recipients | artifact.watcher_recipients
        users.each do |user|
          artifact_add(user, artifact).deliver_later
        end
      end

      def deliver_artifact_edit(artifact, newest_comment)
        users = artifact.recipients | artifact.watcher_recipients
        users.each do |user|
          artifact_edit(user, artifact, newest_comment).deliver_later
        end
      end

      def artifact_add(user, artifact)
        redmine_headers('Project' => artifact.project.id,
                        'Artifact-Id' => artifact.id,
                        'Artifact-Author' => artifact.author.login)

        message_id artifact

        @re_artifact_properties = artifact
        @author = artifact.author
        @artifact_url = url_for(:controller => 're_artifact_properties', :action => 'show', :id => artifact.id)

        @created_by_user = User.find(artifact.created_by)

        mail :to => user,
          :subject => "[#{artifact.project.name} - ##{artifact.id}] #{artifact.name}"
      end

      def artifact_edit(user, artifact, newest_comment)
        redmine_headers('Project' => artifact.project.id,
                        'Artifact-Id' => artifact.id,
                        'Artifact-Author' => artifact.author.login)

        message_id artifact

        @re_artifact_properties = artifact
        @author = artifact.author
        @comment = newest_comment

        @artifact_url = url_for(:controller => 're_artifact_properties', :action => 'show', :id => artifact.id)

        @updated_by_user = User.find(artifact.updated_by)

        mail :to => user,
          :subject => "[#{artifact.project.name} - ##{artifact.id}] #{artifact.name}"
      end
    end
  end
end

RedmineExtensions::PatchManager.register_model_patch 'Mailer', 'RedmineRe::MailerPatch'
