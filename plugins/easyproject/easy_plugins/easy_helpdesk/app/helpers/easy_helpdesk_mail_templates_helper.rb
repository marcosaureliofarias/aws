module EasyHelpdeskMailTemplatesHelper
  def easy_helpdesk_replacable_tokens
    %w(task_id task_id_without_hash task_subject spent_time assignee author mail_to task_note user_signature date task_tracker task_project
    task_description task_status task_priority task_estimated_hours task_done_ratio task_public_url task_closed_on
    task_due_date task_start_date user_name user_first_name user_last_name task_history task_last_journal)
  end

  def easy_helpdesk_replacable_tokens_info
    easy_helpdesk_replacable_tokens.map{|t| "%#{t}% (#{l(:text_easy_helpdesk_mail_template_replacement_for)} #{l(t, :scope => :text_easy_helpdesk_mail_template_dynamic_replacement)})"}.join('<br />').html_safe
  end
end
