class EasyJournalsController < ApplicationController

  def new
    @journal = Journal.visible.find(params[:journal_id]) if params[:journal_id]
    if @journal
      user = @journal.user
      text = @journal.notes
    else
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

end
