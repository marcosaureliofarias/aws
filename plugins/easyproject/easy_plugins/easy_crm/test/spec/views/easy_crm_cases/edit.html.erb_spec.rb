require_relative '../../spec_helper'

describe 'easy_crm_cases/edit', logged: :admin do
  helper :easy_crm, :custom_fields
  before do
    allow(view).to receive(:is_mobile_device?).and_return(false)
    # view.extend EasyCrmHelper
    # view.extend CustomFieldsHelper
  end

  it 'should show form' do

    assign(:easy_crm_case, FactoryGirl.create(:easy_crm_case, :with_custom_fields))

    render
  end
end
