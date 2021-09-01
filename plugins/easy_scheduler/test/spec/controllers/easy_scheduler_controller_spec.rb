require 'easy_extensions/spec_helper'
describe EasySchedulerController, logged: :admin do
  before { allow(Setting).to receive(:rest_api_enabled) { '1' } }

  context '#user_allocation_data' do
    context 'with org chart subordinates', if: EasyScheduler.easy_org_chart? do
      it 'should get users if my_subordinates options passed' do
        allow(EasyOrgChart::Tree).to receive(:children_for).with(User.current.id, true) { [1, 5, 10] }
        get :user_allocation_data, params: { user_ids: [nil, '', 'my_subordinates', '4'] }, format: :json
        expect(assigns(:principal_ids)).to match_array([1, '4', 5, 10])
      end

      it 'should get users if my_subordinates options passed' do
        allow(EasyOrgChart::Tree).to receive(:children_for).with(User.current.id, false) { [1, 5, 10] }
        get :user_allocation_data, params: { user_ids: [nil, '', 'my_subordinates_tree', '4'] }, format: :json
        expect(assigns(:principal_ids)).to match_array([1, '4', 5, 10])
      end
    end
  end
end
