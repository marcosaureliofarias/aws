Rys::Patcher.add('EntityAttributeHelper') do

  apply_if_plugins :easy_extensions

  included do

    def format_html_issue_attribute_with_last_comments(entity_class, attribute, unformatted_value, options = {})

      if Rys::Feature.active?('show_last_comments_on_issue.index') && attribute.name == :last_comments
        format_html_last_comments(format_last_comments(unformatted_value))
      else
        format_html_issue_attribute_without_last_comments(entity_class, attribute, unformatted_value, options)
      end
    end

    def format_issue_attribute_with_last_comments(entity_class, attribute, unformatted_value, options={})
      if Rys::Feature.active?('show_last_comments_on_issue.index') && attribute.name == :last_comments
        format_last_comments(unformatted_value).join("\r\n")
      else
        format_issue_attribute_without_last_comments(entity_class, attribute, unformatted_value, options)
      end
    end

    # @param [Array<Journal>] comments
    def format_last_comments(comments)
      s = []
      comments.each do |comment|
        initials = comment.user.initials if comment.user.present?
        s << "#{ initials } #{ format_date(comment.created_on) } #{ ActionController::Base.helpers.strip_tags(comment.notes) }"
      end
      s
    end

    def format_html_last_comments(comments)
      s = ''
      comments.each do |comment|
        s.concat "<div>#{ comment }</div>"
      end
      s.html_safe
    end

    alias_method_chain :format_html_issue_attribute, :last_comments
    alias_method_chain :format_issue_attribute, :last_comments
  end

end
