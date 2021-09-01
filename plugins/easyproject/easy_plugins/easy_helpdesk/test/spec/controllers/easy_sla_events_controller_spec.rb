require 'easy_extensions/spec_helper'

describe EasySlaEventsController, logged: :admin do
  include_context 'sla_event_support'

  it 'should destroy if admin' do
    expect { delete :destroy, params: { project_id: easy_sla_event.project_id, id: easy_sla_event } }
      .to change(EasySlaEvent, :count).by(-1)
    expect(response).to have_http_status(302)
  end

  it 'should destroy if has permission' do
    with_current_user(user_allowed_to_manage_sla_event) do
      expect { delete :destroy, params: { project_id: easy_sla_event.project_id, id: easy_sla_event } }
        .to change(EasySlaEvent, :count).by(-1)
      expect(response).to have_http_status(302)
    end
  end

  it 'should not be allowed to destroy ' do
    role.remove_permission! :manage_easy_sla_events
    with_current_user(user_allowed_to_manage_sla_event) do
      expect { delete :destroy, params: { project_id: easy_sla_event.project_id, id: easy_sla_event } }
        .to change(EasySlaEvent, :count).by(0)
      expect(response).to have_http_status(403)
    end
  end
end
