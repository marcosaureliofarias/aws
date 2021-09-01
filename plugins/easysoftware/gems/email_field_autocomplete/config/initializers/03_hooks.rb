# Hooks definitions
# http://www.redmine.org/projects/redmine/wiki/Hooks

module EmailFieldAutocomplete
  class Hooks < ::Redmine::Hook::ViewListener
    render_on :view_issues_form_details_bottom, partial: 'issues/email_field_autocomplete/view_issues_form_details_bottom'
    render_on :placeholder_email_autocomplete, partial: 'issues/email_field_autocomplete/email_placeholder'
  end
end
