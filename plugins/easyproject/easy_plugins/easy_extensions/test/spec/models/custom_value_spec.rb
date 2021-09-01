require 'easy_extensions/spec_helper'

describe CustomValue, logged: :admin do
  it 'attachments visibility' do
    cf = CustomField.new
    cv = CustomValue.new(custom_field: cf, customized_type: 'Principal', customized: User.current)
    expect(cv.attachments_visible?).to eq(true)
    expect(cv.attachments_editable?).to eq(true)
    expect(cv.attachments_deletable?).to eq(true)
  end
end
