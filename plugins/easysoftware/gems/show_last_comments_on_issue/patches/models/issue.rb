Rys::Patcher.add('Issue') do

  apply_if_plugins :easy_extensions

  instance_methods do

    def last_comments
      journals.with_notes.non_system.last(Issue.last_comments_limit)
    end
  end

  class_methods do
    def last_comments_limit
      EasySetting.value('issue_last_comments_limit').presence || Issue.last_comments_default_limit
    end

    def last_comments_default_limit
      5
    end
  end

end
