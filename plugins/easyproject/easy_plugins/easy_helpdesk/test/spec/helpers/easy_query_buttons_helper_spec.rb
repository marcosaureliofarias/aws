require 'easy_extensions/spec_helper'

describe EasyQueryButtonsHelper, logged: :admin do
  context '#easy_sla_event_query_additional_ending_buttons' do
    include_context 'sla_event_support'

    subject(:sla_event_query_buttons) { helper.easy_sla_event_query_additional_ending_buttons(easy_sla_event) }
    
    it 'button Delete should be added for admin' do
      expect(sla_event_query_buttons).to have_link(I18n.t(:button_delete), href: /#{project_easy_sla_event_path(easy_sla_event.project_id, easy_sla_event.id)}/)
    end

    it 'button Delete should be added for user allowed' do
      with_current_user(user_allowed_to_manage_sla_event) do
        expect(sla_event_query_buttons).to have_link(I18n.t(:button_delete), href: /#{project_easy_sla_event_path(easy_sla_event.project_id, easy_sla_event.id)}/)
      end
    end

    it 'button Delete should not be added if no permissions' do
      role.remove_permission! :manage_easy_sla_events
      with_current_user(user_allowed_to_manage_sla_event) do
        expect(sla_event_query_buttons).not_to have_link(I18n.t(:button_delete), href: /#{project_easy_sla_event_path(easy_sla_event.project_id, easy_sla_event.id)}/)
      end
    end
  end
end
