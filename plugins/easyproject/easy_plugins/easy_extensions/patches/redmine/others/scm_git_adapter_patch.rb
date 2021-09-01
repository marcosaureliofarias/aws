# encoding: utf-8

require 'redmine/scm/adapters/git_adapter'

module EasyPatch
  module ScmGitAdapterPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :git_cmd, :easy_extensions
        alias_method_chain :revisions, :easy_extensions

        def changeset_branches(scmid)
          branches = []
          cmd_args = %w|branch --no-color --no-abbrev --contains| << scmid
          git_cmd(cmd_args) do |io|
            io.each_line do |line|
              branch_rev = line.match(/\s*(\*?)\s*(.*?)$/)
              next unless branch_rev
              name = scm_iconv('UTF-8', @path_encoding, branch_rev[2])
              branches << name.strip if name.present?
            end
          end
          branches.sort!
          branches
        rescue Redmine::Scm::Adapters::AbstractAdapter::ScmCommandAborted
          []
        end

        # @param [String] git_url git@github.com
        # @param [String] repo_name
        def ensure!(git_url, repo_name = nil)
          FileUtils.mkdir(repo_container_dir) unless repo_container_dir.exist?

          if repo_name.nil? && (m = (git_url.match(/^\S*\/(\S+)$/)))
            repo_name = m[1]
          end
          raise Redmine::Scm::Adapters::AbstractAdapter::ScmCommandAborted, "unknown repository name for `#{git_url}`" if repo_name.nil?

          repository_url = repo_container_dir.join(File.basename(repo_name))

          if File.exist?(repository_url)
            repo_name      = "#{SecureRandom.hex(2)}_#{repo_name}"
            repository_url = repo_container_dir.join(repo_name)
          end

          Dir.chdir(repo_container_dir) do
            unless repository_url.exist?
              git_clone(git_url, repo_name)
            end
          end

          repository_url
        end

        def destroy(repository)
          FileUtils.rm_rf repository.root_url
        end

        private

        def git_clone(git_url, repo_name)
          git_output = shellout("#{Redmine::Scm::Adapters::GitAdapter.sq_bin} clone --mirror \"#{git_url}\" #{repo_name}") { |io| io.read }
          if $? && $?.exitstatus != 0
            if $?.exitstatus == 128 && File.exist?(repo_name)
              Rails.logger.warn "Repository #{git_url}, possible redirect, Git reported: #{git_output}"
            else
              Rails.logger.warn "Failed to create a repository #{git_url}, Git reported: #{git_output}"
              raise Redmine::Scm::Adapters::AbstractAdapter::ScmCommandAborted, "git exited with non-zero status: #{$?.exitstatus}"
            end
          end
        end

        def repo_container_dir
          Rails.root.join(EasySetting.value('git_repository_path'))
        end

      end
    end

    module InstanceMethods

      def git_cmd_with_easy_extensions(args, options = {}, &block)
        repo_path = root_url || url
        if File.exist?(repo_path)
          git_cmd_without_easy_extensions(args, options, &block)
        end
      end

      def revisions_with_easy_extensions(path, identifier_from, identifier_to, options={})
        revs = revisions_without_easy_extensions(path, identifier_from, identifier_to, options)
        revs.each { |rev| puts rev.message = rev.message.force_encoding('UTF-8') }
        revs
      end

    end

    module ClassMethods
    end

  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Scm::Adapters::GitAdapter', 'EasyPatch::ScmGitAdapterPatch'
