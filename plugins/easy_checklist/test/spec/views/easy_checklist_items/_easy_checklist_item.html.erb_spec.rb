require 'easy_extensions/spec_helper'

describe 'easy_checklist_items/_easy_checklist_item', logged: :admin do
  let(:issue) { FactoryGirl.build_stubbed(:issue) }
  let(:easy_checklist) { FactoryGirl.build_stubbed(:easy_checklist, entity: issue) }
  let(:easy_checklist_item) { FactoryGirl.build_stubbed(:easy_checklist_item, easy_checklist: easy_checklist, subject: 'www.google.com') }

  it 'render link' do
    options = _default_render_options.merge locals: { easy_checklist_item: easy_checklist_item }
    with_settings :text_formatting => 'none' do
      render options
    end
    expect(rendered).to include easy_checklist_item.subject
  end

end
