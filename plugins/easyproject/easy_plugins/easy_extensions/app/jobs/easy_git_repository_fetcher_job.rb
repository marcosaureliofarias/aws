class EasyGitRepositoryFetcherJob < EasyActiveJob

  def perform(repository)
    return if !ensure_repository(repository)

    if !system("cd #{repository.url} && git fetch")
      log_info "Git fetch error ##{repository.id}:#{repository.url}"
      return
    end

    repository.fetch_changesets
  end

  private

  def ensure_repository(repository)
    if File.exist?(repository.url)
      return true
    else
      clone_repository(repository)
    end
  end

  def clone_repository(repository)
    return false if repository.easy_repository_url.blank?

    begin
      repository_url = repository.scm.ensure!(repository.easy_repository_url)
      repository.update(url: repository_url, root_url: repository_url)

      return true
    rescue Redmine::Scm::Adapters::CommandFailed => e
      return false
    end
  end

end
