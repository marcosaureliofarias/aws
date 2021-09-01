require 'easy_extensions/spec_helper'

describe CustomFieldValue do
  let(:cf) { CustomField.new(field_format: 'attachment') }
  let(:cfv) { CustomFieldValue.new(custom_field: cf) }

  context 'editable', logged: :admin do
    it 'admin' do
      expect(cfv).to be_editable
    end

    it 'regular', logged: true do
      expect(cfv).not_to be_editable
    end
  end
end
